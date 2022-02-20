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

public class Life.Widgets.DrawingBoard : Gtk.DrawingArea {

    public State state { get; construct; }
    public Drawable drawable { get; construct; }
    public Editable editable { get; construct; }
    public ColorPalette color_palette { get; construct; }
    public int width { get { return (int) drawable.width_points * state.scale; } }
    public int height { get { return (int) drawable.height_points * state.scale; } }
    public double reverse_scale { get { return 1 / ((double) state.scale); } }

    private Point? cursor_position = null;
    private bool is_pressing = false;

    public DrawingBoard (State state) {
        Object (
            state: state,
            drawable: state.drawable,
            editable: state.editable,
            color_palette: new ColorPalette (),
            hexpand: true,
            vexpand: true,
            halign: Gtk.Align.CENTER,
            valign: Gtk.Align.CENTER
        );
    }

    construct {
        connect_signals ();
    }

    public override Gtk.SizeRequestMode get_request_mode () {
        return Gtk.SizeRequestMode.CONSTANT_SIZE;
    }

    public override void get_preferred_width (out int min, out int nat) {
        min = width;
        nat = width;
    }

    public override void get_preferred_height (out int min, out int nat) {
        min = height;
        nat = height;
    }

    private void connect_signals () {
        draw.connect (on_draw);

        motion_notify_event.connect (on_pointer_move);
        button_press_event.connect (on_button_press);
        button_release_event.connect (on_button_release);
        leave_notify_event.connect (on_pointer_leave);

        add_events (Gdk.EventMask.POINTER_MOTION_MASK);
        add_events (Gdk.EventMask.BUTTON_PRESS_MASK);
        add_events (Gdk.EventMask.BUTTON_RELEASE_MASK);
        add_events (Gdk.EventMask.LEAVE_NOTIFY_MASK);

        state.tick.connect_after (() => {
            queue_resize ();
            queue_draw ();
        });
        state.notify["scale"].connect (() => {
            queue_resize ();
            queue_draw ();
        });
    }

    private bool on_draw (Cairo.Context ctx) {
        reset_background (ctx);
        draw_grid (ctx);
        draw_live_cells (ctx);
        highlight_cursor (ctx);
        return false;
    }

    private void reset_background (Cairo.Context ctx) {
        var dcc = color_palette.dead_cell_color;
        ctx.set_source_rgba (dcc.red, dcc.green, dcc.blue, dcc.alpha);
        ctx.rectangle (0, 0, width, height);
        ctx.fill ();
    }

    private void draw_grid (Cairo.Context ctx) {
        var bgc = color_palette.background_color;
        ctx.set_source_rgba (bgc.red, bgc.green, bgc.blue, bgc.alpha);
        ctx.set_line_width (2);

        for (var i = 0; i <= drawable.width_points; i++) {
            ctx.move_to (i * state.scale, 0);
            ctx.line_to (i * state.scale, height);
        }

        for (var j = 0; j <= drawable.height_points; j++) {
            ctx.move_to (0, j * state.scale);
            ctx.line_to (width, j * state.scale);
        }

        ctx.stroke ();
    }

    private void draw_live_cells (Cairo.Context ctx) {
        var lcc = color_palette.live_cell_color;
        ctx.set_source_rgba (lcc.red, lcc.green, lcc.blue, lcc.alpha);

        drawable.draw (visible_drawable_rec (ctx), point => {
            var top_left = drawable_to_cairo (point);
            ctx.rectangle (top_left.x, top_left.y, state.scale - 2, state.scale - 2);
        });

        ctx.fill ();
    }

    private void highlight_cursor (Cairo.Context ctx) {
        if (cursor_position == null) {
            return;
        }

        var ac = color_palette.accent_color;
        ctx.set_source_rgba (ac.red, ac.green, ac.blue, ac.alpha / 2);
        var top_left = drawable_to_cairo (cursor_position);
        ctx.rectangle (top_left.x - 1, top_left.y - 1, state.scale, state.scale);
        ctx.set_line_width (2);
        ctx.stroke ();
    }

    private Point drawable_to_cairo (Point drawable_point) {
        return drawable_point.x_add (drawable.width_points / 2)
            .y_add (-drawable.height_points / 2 + 1)
            .flip_h ()
            .scale (state.scale);
    }

    private Point cairo_to_drawable (Point cairo_point) {
        return cairo_point
            .scale_imprecise (reverse_scale)
            .flip_h ()
            .y_add (drawable.height_points / 2 - 1)
            .x_add (-drawable.width_points / 2);
    }

    private Rectangle visible_drawable_rec (Cairo.Context ctx) {
        Gdk.Rectangle rec;
        Gdk.cairo_get_clip_rectangle (ctx, out rec);


        var bottom_left_cairo = new Point (rec.x, rec.y + rec.height);
        var bottom_left_drawable = cairo_to_drawable (bottom_left_cairo);

        var heigth_drawable = Math.lround (rec.height * reverse_scale);
        var width_drawable = Math.lround (rec.width * reverse_scale);

        return new Rectangle (
            bottom_left_drawable.add (-10),
            heigth_drawable + 20,
            width_drawable + 20
        );
    }

    private bool on_pointer_move (Gdk.EventMotion event) {
        var new_point = new Point (Math.lround (event.x), Math.lround (event.y));
        var new_cursor_position = cairo_to_drawable (new_point);
        var window = get_window ();
        if (new_cursor_position != cursor_position && window != null) {
            if (is_pressing) {
                if (state.active_tool == State.Tool.PENCIL) {
                    editable.set_alive (new_cursor_position, true);
                } else if (state.active_tool == State.Tool.ERASER) {
                    editable.set_alive (new_cursor_position, false);
                }
            }

            Point prev_point;
            if (cursor_position != null) {
                prev_point = drawable_to_cairo (cursor_position);
            } else {
                prev_point = new_point;
            }

            var rect = Gdk.Rectangle () {
                x = (int) int64.min (new_point.x, prev_point.x) - 2 * state.scale,
                y = (int) int64.min (new_point.y, prev_point.y) - 2 * state.scale,
                width = (int) (new_point.x - prev_point.x).abs () + 4 * state.scale,
                height = (int) (new_point.y - prev_point.y).abs () + 4 * state.scale
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
            editable.set_alive (cursor_position, true);
        } else if (state.active_tool == State.Tool.ERASER) {
            editable.set_alive (cursor_position, false);
        }

        var window = get_window ();
        if (window != null) {
            var rect = Gdk.Rectangle () {
                x = (int) Math.lround (event.x) - 2 * state.scale,
                y = (int) Math.lround (event.y) - 2 * state.scale,
                width = 4 * state.scale,
                height = 4 * state.scale
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
        cursor_position = null;
        var window = get_window ();
        if (window != null) {
            var rect = Gdk.Rectangle () {
                x = (int) event.x - 2 * state.scale,
                y = (int) event.y - 2 * state.scale,
                width = 4 * state.scale,
                height = 4 * state.scale
            };

            window.invalidate_rect (rect, false);
        }

        return true;
    }
}
