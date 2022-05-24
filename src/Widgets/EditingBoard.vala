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

public class Life.Widgets.EditingBoard : DrawingBoard {

    public const Gtk.TargetEntry[] TARGET_ENTRIES = {
        {"PATTERN", Gtk.TargetFlags.SAME_APP | Gtk.TargetFlags.OTHER_WIDGET, 0}
    };

    public State state { get; set; }

    private bool is_pressing = false;

    public EditingBoard (State state) {
        base (state, state.drawable);
        this.state = state;
    }

    construct {
        connect_signals ();
        set_up_drag_target ();
    }

    private void connect_signals () {
        motion_notify_event.connect (on_pointer_move);
        button_press_event.connect (on_button_press);
        button_release_event.connect (on_button_release);
        leave_notify_event.connect (on_pointer_leave);

        add_events (Gdk.EventMask.POINTER_MOTION_MASK);
        add_events (Gdk.EventMask.BUTTON_PRESS_MASK);
        add_events (Gdk.EventMask.BUTTON_RELEASE_MASK);
        add_events (Gdk.EventMask.LEAVE_NOTIFY_MASK);
    }

    private void set_up_drag_target () {
        Gtk.drag_dest_set (
            this,
            Gtk.DestDefaults.HIGHLIGHT | Gtk.DestDefaults.MOTION,
            TARGET_ENTRIES,
            Gdk.DragAction.COPY
        );

        drag_motion.connect (on_drag_motion);
        drag_leave.connect (on_drag_leave);
        drag_drop.connect (on_drag_drop);
        drag_data_received.connect (on_drag_data_received);
    }


    protected override void apply_highlights (Cairo.Context ctx) {
        if (cursor_position == null) {
            return;
        }

        var ac = color_palette.accent_color;
        ctx.set_source_rgba (ac.red, ac.green, ac.blue, ac.alpha / 2);
        var top_left = drawable_to_cairo (cursor_position);
        ctx.rectangle (top_left.x - 1, top_left.y - 1, scaleable.scale, scaleable.scale);
        ctx.set_line_width (2);
        ctx.stroke ();
    }

    private bool on_pointer_move (Gdk.EventMotion event) {
        return on_pointer_move_xy (
            (int) event.x,
            (int) event.y
        );
    }

    private bool on_pointer_move_xy (int x, int y) {
        var new_point = new Point (x, y);
        var new_cursor_position = cairo_to_drawable (new_point);
        var window = get_window ();
        if (new_cursor_position != cursor_position && window != null) {
            if (is_pressing) {
                if (state.active_tool == State.Tool.PENCIL) {
                    state.editable.set_alive (new_cursor_position, true);
                } else if (state.active_tool == State.Tool.ERASER) {
                    state.editable.set_alive (new_cursor_position, false);
                }
            }

            Point prev_point;
            if (cursor_position != null) {
                prev_point = drawable_to_cairo (cursor_position);
            } else {
                prev_point = new_point;
            }

            var rect = Gdk.Rectangle () {
                x = (int) int64.min (new_point.x, prev_point.x) - 2 * scaleable.scale,
                y = (int) int64.min (new_point.y, prev_point.y) - 2 * scaleable.scale,
                width = (int) (new_point.x - prev_point.x).abs () + 4 * scaleable.scale,
                height = (int) (new_point.y - prev_point.y).abs () + 4 * scaleable.scale
            };

            cursor_position = new_cursor_position;
            window.invalidate_rect (rect, false);
            return true;
        }

        return false;
    }

    private bool on_button_press (Gdk.EventButton event) {
        if (event.button != Gdk.BUTTON_PRIMARY) {
            return false;
        }

        is_pressing = true;
        if (state.active_tool == State.Tool.PENCIL) {
            state.editable.set_alive (cursor_position, true);
        } else if (state.active_tool == State.Tool.ERASER) {
            state.editable.set_alive (cursor_position, false);
        }

        var window = get_window ();
        if (window != null) {
            var rect = Gdk.Rectangle () {
                x = (int) Math.lround (event.x) - 2 * scaleable.scale,
                y = (int) Math.lround (event.y) - 2 * scaleable.scale,
                width = 4 * scaleable.scale,
                height = 4 * scaleable.scale
            };

            window.invalidate_rect (rect, false);
        }

        return false;
    }

    private bool on_button_release (Gdk.EventButton event) {
        if (event.button != Gdk.BUTTON_PRIMARY) {
            return false;
        }

        is_pressing = false;
        return true;
    }

    private bool on_pointer_leave (Gdk.EventCrossing event) {
        return on_pointer_leave_xy ((int) event.x, (int) event.y);
    }

    private bool on_pointer_leave_xy (int x, int y) {
        cursor_position = null;
        var window = get_window ();
        if (window != null) {
            var rect = Gdk.Rectangle () {
                x = x - 2 * scaleable.scale,
                y = y - 2 * scaleable.scale,
                width = 4 * scaleable.scale,
                height = 4 * scaleable.scale
            };

            window.invalidate_rect (rect, false);
        }

        return true;
    }

    private bool on_drag_motion (Gdk.DragContext ctx, int x, int y, uint time_) {
        on_pointer_move_xy (x, y);
        return true;
    }

    private void on_drag_leave (Gdk.DragContext ctx, uint time_) {
        if (cursor_position != null) {
            var point = drawable_to_cairo (cursor_position);
            on_pointer_leave_xy ((int) point.x, (int) point.y);
        }
    }

    private bool on_drag_drop (Gdk.DragContext ctx, int x, int y, uint time_) {
        Gtk.drag_get_data (this, ctx, Gdk.Atom.intern ("PATTERN", false), time_);
        return true;
    }

    private void on_drag_data_received (
        Gdk.DragContext ctx,
        int x,
        int y,
        Gtk.SelectionData data,
        uint target_type,
        uint time_
    ) {
        var pattern = ((Pattern[]) data.get_data ())[0];
        var center = cairo_to_drawable (new Point (x, y));
        pattern.write_into (state.editable, center, false);
        state.simulation_updated ();

        on_pointer_move_xy (x, y);

        Gtk.drag_finish (ctx, true, false, time_);
    }
}
