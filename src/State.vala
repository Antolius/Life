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

    public override int scale { get; set; default = DEFAULT_SCALE; }
    public int speed { get; set; default = DEFAULT_SPEED; }
    public bool is_playing { get; set; default = false; }
    public Tool active_tool { get; set; default = Tool.PENCIL; }
    public bool showing_stats { get; set; default = false; }
    public int library_position { get; set; }
    public string title { get; set; default = "Untitled*"; }
    public File? file { get; set; }

    public Gtk.Clipboard clipboard { get; construct; }
    public Drawable drawable { get; construct; }
    public Editable editable { get; construct; }
    public Stepper stepper { private get; construct; }
    public int64 generation { get { return stepper.generation; } }

    private uint? timer_id;

    public virtual signal void simulation_updated () {}

    public signal void info (InfoModel model) {}

    public State (Drawable drawable, Editable editable, Stepper stepper) {
        Object (
            clipboard: Gtk.Clipboard.get (
                Gdk.Atom.intern_static_string (Constants.APP_CLIPBOARD)
            ),
            drawable: drawable,
            editable: editable,
            stepper: stepper
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
    }

    public void step_by_one () {
        stepper.step ();
        simulation_updated ();
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

    public async bool open (string path) {
        try {
            file = File.new_for_path (path);
            var stream = yield file.read_async ();
            var pattern = yield Pattern.from_plaintext (stream);
            title = pattern.name;
            clear ();
            pattern.write_into_centered (editable);
            simulation_updated ();
            return true;
        } catch (Error err) {
            warning (
                "Failed to open file %s, %s",
                path,
                print_err (err)
            );
            return false;
        }
    }

    public async bool save (string? new_path = null) {
        var saved_file_title = title;
        if (new_path != null) {
            var new_path_with_suffix = new_path;
            if (!new_path_with_suffix.has_suffix (".cells")) {
                new_path_with_suffix += ".cells";
            }

            file = File.new_for_path (new_path_with_suffix);
            var filename = file.get_basename ();
            saved_file_title = filename.substring (0, filename.length - 6);
        }

        if (file == null) {
            warning ("Cannot save null file");
            return false;
        }

        try {
            var stream = yield file.replace_readwrite_async (
                null,
                false,
                FileCreateFlags.REPLACE_DESTINATION
            );
            var shape = new CutoutShape.entire (drawable);
            var pattern = Pattern.from_shape (saved_file_title, shape);
            pattern.write_as_plaintext (stream.output_stream);
            title = saved_file_title;
            return true;
        } catch (Error err) {
            warning (
                "Failed to save file %s, %s",
                file.get_uri (),
                print_err (err)
            );
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
            step_by_one ();
            return Source.CONTINUE;
        });
    }

    private void stop_ticking () {
        Source.remove (timer_id);
        timer_id = null;
    }

    private string print_err (Error err) {
        var format = "Error Message: \"%s\", Error code: %d, Error domain: %";
        format += uint32.FORMAT;
        return (format).printf (
            err.message,
            err.code,
            err.domain
        );
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
