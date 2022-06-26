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
        {Constants.PATTERN, Gtk.TargetFlags.SAME_APP | Gtk.TargetFlags.OTHER_WIDGET, 0}
    };

    public State state { get; set; }

    private bool is_pressing = false;
    private Gee.List<SelectionArea> select_area =
        new Gee.LinkedList<SelectionArea> ();
    private SelectionArea? starting_select_area = null;

    public EditingBoard (State state) {
        base (state, state.drawable);
        this.state = state;

        connect_to_state ();
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
        drag_motion.connect (on_drag_motion);
        drag_leave.connect (on_drag_leave);
        drag_drop.connect (on_drag_drop);
        drag_data_received.connect (on_drag_data_received);
    }

    private void connect_to_state () {
        state.simulation_updated.connect_after (() => {
            select_area.clear ();
        });
        state.notify["saving-in-progress"].connect (
            adapt_drag_target_to_file_ops
        );
        state.notify["opening-in-progress"].connect (
            adapt_drag_target_to_file_ops
        );
        adapt_drag_target_to_file_ops ();
    }

    private void adapt_drag_target_to_file_ops () {
        if (state.saving_in_progress || state.opening_in_progress) {
            Gtk.drag_dest_unset (this);
        } else {
            Gtk.drag_dest_set (
                this,
                Gtk.DestDefaults.HIGHLIGHT | Gtk.DestDefaults.MOTION,
                TARGET_ENTRIES,
                Gdk.DragAction.COPY
            );
        }
    }


    protected override void apply_highlights (Cairo.Context ctx) {
        var ac = color_palette.accent_color;

        if (cursor_position != null) {
            ctx.set_source_rgba (ac.red, ac.green, ac.blue, ac.alpha / 2);
            var top_left = drawable_to_cairo (cursor_position);
            ctx.rectangle (
                top_left.x - 1,
                top_left.y - 1,
                scaleable.scale,
                scaleable.scale
            );
            ctx.set_line_width (2);
            ctx.stroke ();
        }

        if (!select_area.is_empty) {
            foreach (var select in select_area) {
                var drawable_point = select.rect.top_left ().y_add (-1);
                var top_left = drawable_to_cairo (drawable_point);
                ctx.rectangle (
                    top_left.x - 1,
                    top_left.y - 1,
                    scaleable.scale * select.rect.width + 1,
                    scaleable.scale * select.rect.height + 1
                );
            }

            ctx.set_source_rgba (ac.red, ac.green, ac.blue, ac.alpha / 6);
            ctx.fill_preserve ();
        }
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
        if (new_cursor_position != cursor_position) {
            if (is_pressing) {
                if (state.active_tool == State.Tool.POINTER) {
                    if (starting_select_area != null) {
                        select_area.add (starting_select_area);
                        starting_select_area = null;
                    }

                    if (!select_area.is_empty) {
                        var selection = select_area.last ();
                        selection.expand_to (new_cursor_position);
                    }
                } else if (state.active_tool == State.Tool.PENCIL) {
                    state.editable.set_alive (new_cursor_position, true);
                } else if (state.active_tool == State.Tool.ERASER) {
                    state.editable.set_alive (new_cursor_position, false);
                }
            }

            cursor_position = new_cursor_position;
            trigger_redraw ();
            return true;
        }

        return false;
    }

    private bool on_button_press (Gdk.EventButton event) {
        if (state.saving_in_progress || state.opening_in_progress) {
            return false;
        }

        if (event.button == Gdk.BUTTON_PRIMARY) {
            return on_primary_button_press (event);
        } else if (event.button == Gdk.BUTTON_SECONDARY) {
            return on_secondary_button_press (event);
        }

        return false;
    }

    private bool on_primary_button_press (Gdk.EventButton event) {
        var cairo_x = (int) Math.lround (event.x);
        var cairo_y = (int) Math.lround (event.y);

        is_pressing = true;
        if (state.active_tool == State.Tool.POINTER) {
            var adding = (event.state & Gdk.ModifierType.SHIFT_MASK) != 0;
            if (!adding) {
                select_area.clear ();
            }

            var point = cairo_to_drawable (new Point (cairo_x, cairo_y));
            starting_select_area = new SelectionArea (point);
        } else if (state.active_tool == State.Tool.PENCIL) {
            state.editable.set_alive (cursor_position, true);
            select_area.clear ();
            starting_select_area = null;
        } else if (state.active_tool == State.Tool.ERASER) {
            state.editable.set_alive (cursor_position, false);
            select_area.clear ();
            starting_select_area = null;
        }

        trigger_redraw ();

        return false;
    }

    private bool on_secondary_button_press (Gdk.EventButton event) {
        var cairo_x = (int) Math.lround (event.x);
        var cairo_y = (int) Math.lround (event.y);
        var point = cairo_to_drawable (new Point (cairo_x, cairo_y));

        var select_rects = new Gee.LinkedList<Rectangle> ();
        foreach (var select in select_area) {
            select_rects.add (select.rect);
        }

        var menu = new EditingBoardPopupMenu (state, point, select_rects);
        menu.drawable_updated.connect (() => {
            select_area.clear ();
            trigger_redraw ();
        });
        menu.popup_at_pointer (event);

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

    private bool on_drag_motion (Gdk.DragContext ctx, int x, int y, uint time) {
        on_pointer_move_xy (x, y);
        return true;
    }

    private void on_drag_leave (Gdk.DragContext ctx, uint time) {
        if (cursor_position != null) {
            var point = drawable_to_cairo (cursor_position);
            on_pointer_leave_xy ((int) point.x, (int) point.y);
        }
    }

    private bool on_drag_drop (Gdk.DragContext ctx, int x, int y, uint time) {
        var pattern_atom = Gdk.Atom.intern_static_string (Constants.PATTERN);
        Gtk.drag_get_data (this, ctx, pattern_atom, time);
        return true;
    }

    private void on_drag_data_received (
        Gdk.DragContext ctx,
        int x,
        int y,
        Gtk.SelectionData data,
        uint target_type,
        uint time
    ) {
        var pattern = ((Pattern[]) data.get_data ())[0];
        var center = cairo_to_drawable (new Point (x, y));
        pattern.write_into.begin (state.editable, center, false, (obj, res) => {
            pattern.write_into.end (res);

            state.simulation_updated ();
            on_pointer_move_xy (x, y);
            Gtk.drag_finish (ctx, true, false, time);
        });
    }

    private void trigger_redraw () {
        var window = get_window ();
        if (window != null) {
            window.invalidate_rect (null, false);
        }
    }
}

class Life.Widgets.SelectionArea : Object {
    public Point starting_point { get; construct; }
    public Rectangle rect { get; set; }

    public SelectionArea (Point starting_point) {
        Object (
            starting_point: starting_point,
            rect: new Rectangle (starting_point, 1, 1)
        );
    }

    public void expand_to (Point point) {
        rect = new Rectangle (
            new Point (
                int64.min (starting_point.x, point.x),
                int64.min (starting_point.y, point.y)
            ),
            (starting_point.y - point.y).abs () + 1,
            (starting_point.x - point.x).abs () + 1
        );
    }
}
