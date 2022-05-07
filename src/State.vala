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

public class Life.State : Object {

    public const int MIN_SPEED = 1;       // 1 generation per second
    public const int MAX_SPEED = 20;      // 20 generations per second
    private const int DEFAULT_SPEED = 10; // 10 generations per second
    private const int DEFAULT_SCALE = 10; // 10px per board point

    public int scale { get; set; default = DEFAULT_SCALE; }
    public int speed { get; set; default = DEFAULT_SPEED; }
    public bool is_playing { get; set; default = false; }
    public Tool active_tool { get; set; default = Tool.PENCIL; }
    public bool showing_stats { get; set; default = false; }

    public Drawable drawable { get; construct; }
    public Editable editable { get; construct; }
    public Stepper stepper { private get; construct; }
    public int64 generation { get { return stepper.generation; } }

    private uint? timer_id;

    public virtual signal void tick () {
        stepper.step ();
    }

    public State (Drawable drawable, Editable editable, Stepper stepper) {
        Object (
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

    public void clear () {
        editable.clear_all ();
        stepper.generation = 0;
        tick ();
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

    private void restart_ticking () {
        stop_ticking ();
        start_ticking ();
    }

    private void start_ticking () {
        if (timer_id != null) {
            return;
        }

        timer_id = Timeout.add (1000 / speed, () => {
            tick ();
            return Source.CONTINUE;
        });
    }

    private void stop_ticking () {
        Source.remove (timer_id);
        timer_id = null;
    }

    public enum Tool {
        POINTER,
        PENCIL,
        ERASER,
    }
}
