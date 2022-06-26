/*
* Copyright 2022 Josip Antoliš. (https://josipantolis.from.hr)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
*/

public class Life.State : Object, Scaleable {

    public enum Tool {
        POINTER,
        PENCIL,
        ERASER,
    }

    public const int MIN_SPEED = 1;      //  1 generation per second
    public const int MAX_SPEED = 20;     // 20 generations per second
    public const int DEFAULT_SPEED = 10; // 10 generations per second
    public const int DEFAULT_SCALE = 10; // 10px per board point

    // Managers to delegate functionality to
    public Gtk.Clipboard clipboard { get; construct; }
    public Drawable drawable { get; construct; }
    public Editable editable { get; construct; }
    public Stepper stepper { private get; construct; }
    public FileManager file_manager { private get; construct; }

    // State of the app
    public override int scale { get; set; default = DEFAULT_SCALE; }
    public int speed { get; set; default = DEFAULT_SPEED; }
    public bool is_playing { get; set; default = false; }
    public Tool active_tool { get; set; default = Tool.PENCIL; }
    public bool showing_stats { get; set; default = false; }
    public int library_position { get; set; }
    public string title { get; set; default = Pattern.DEFAULT_NAME; }
    public bool autosave { get; set; default = true; }
    public bool saving_in_progress { get; set; default = false; }
    public bool opening_in_progress { get; set; default = false; }

    // Derived state
    public File? file { get { return file_manager.open_file; } }
    public int64 generation { get { return stepper.generation; } }

    // Signals for state changes
    public virtual signal void simulation_updated () {}
    public signal void info (InfoModel model) {}

    private uint? timer_id;
    private bool is_stepping = false;

    public State (
        Drawable drawable,
        Editable editable,
        Stepper stepper,
        FileManager file_manager
    ) {
        Object (
            clipboard: Gtk.Clipboard.get (
                Gdk.Atom.intern_static_string (Constants.APP_CLIPBOARD)
            ),
            drawable: drawable,
            editable: editable,
            stepper: stepper,
            file_manager: file_manager
        );
    }

    construct {
        notify["is-playing"].connect (() => {
            if (is_playing) {
                start_ticking ();
            } else {
                stop_ticking ();
            }
        });

        notify["speed"].connect (() => {
            restart_ticking ();
        });

        stepper.step_completed.connect (on_step_completed);
        simulation_updated.connect (trigger_autosave);
        open_autosave ();
    }

    public void step_by_one () {
        is_stepping = true;
        stepper.step ();
    }

    public void clear () {
        editable.clear_all ();
        stepper.generation = 0;
        simulation_updated ();
        is_playing = false;
    }

    public Stats.Metric[] stats () {
        var drawable_stats = drawable.stats ();
        var stepper_stats = stepper.stats ();
        Stats.Metric[] stats = {};
        foreach (var stat in drawable_stats) {
            stats += stat;
        }
        foreach (var stat in stepper_stats) {
            stats += stat;
        }
        return stats;
    }

    private void trigger_autosave () {
        if (autosave) {
            file_manager.autosave_with_debounce ();
        }
    }

    private void open_autosave () {
        opening_in_progress = true;
        file_manager.open_internal_autosave.begin ((obj, res) => {
            var pattern = file_manager.open_internal_autosave.end (res);
            opening_in_progress = false;
            if (pattern != null) {
                title = pattern.name;
                stepper.generation = 0;
                simulation_updated ();
            }
        });
    }

    public async bool open (string path) {
        opening_in_progress = true;
        Idle.add (open.callback);
        yield;
        is_playing = false;
        var pattern = yield file_manager.open (path);
        opening_in_progress = false;
        if (pattern != null) {
            title = pattern.name;
            stepper.generation = 0;
            simulation_updated ();
            return true;
        } else {
            return false;
        }
    }

    public async bool save (string? new_path = null) {
        saving_in_progress = true;
        Idle.add (save.callback);
        yield;
        var pattern = yield file_manager.save (new_path);
        saving_in_progress = false;
        if (pattern != null) {
            title = pattern.name;
            return true;
        } else {
            return false;
        }
    }

    private void restart_ticking () {
        stop_ticking ();
        start_ticking ();
    }

    private void start_ticking () {
        if (timer_id != null) {
            return;
        }

        timer_id = Timeout.add (1000 / speed, () => {
            if (!is_stepping) {
                step_by_one ();
            }

            return Source.CONTINUE;
        });
    }

    private void stop_ticking () {
        if (timer_id != null) {
            Source.remove (timer_id);
            timer_id = null;
        }
    }

    private void on_step_completed () {
        is_stepping = false;
        simulation_updated ();
    }
}

public class Life.InfoModel : Object {

    public string message;
    public Gtk.MessageType message_type;
    public string? action_label;
    public InfoActionHandler? action_handler;

    public InfoModel (
        string message,
        Gtk.MessageType message_type,
        string? action_label = null,
        owned InfoActionHandler? action_handler = null
    ) {
        this.message = message;
        this.message_type = message_type;
        this.action_label = action_label;
        this.action_handler = (owned) action_handler;
    }

}

public delegate void Life.InfoActionHandler ();
