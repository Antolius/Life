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

    public Scaleable scaleable { get; construct; }
    public Drawable drawable { get; construct; }
    public ColorPalette color_palette { get; construct; }
    public int width { get { return (int) drawable.width_points * scaleable.scale; } }
    public int height { get { return (int) drawable.height_points * scaleable.scale; } }
    public double reverse_scale { get { return 1 / ((double) scaleable.scale); } }
    public Point? cursor_position { get; set; }

    public DrawingBoard (Scaleable scaleable, Drawable drawable) {
        Object (
            scaleable: scaleable,
            drawable: drawable,
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

        scaleable.notify["scale"].connect (() => {
            queue_resize ();
            queue_draw ();
        });
    }

    private bool on_draw (Cairo.Context ctx) {
        reset_background (ctx);
        draw_grid (ctx);
        draw_live_cells (ctx);
        apply_highlights (ctx);
        return false;
    }

    protected void reset_background (Cairo.Context ctx) {
        var dcc = color_palette.dead_cell_color;
        ctx.set_source_rgba (dcc.red, dcc.green, dcc.blue, dcc.alpha);
        ctx.rectangle (0, 0, width, height);
        ctx.fill ();
    }

    protected void draw_grid (Cairo.Context ctx) {
        var bgc = color_palette.background_color;
        ctx.set_source_rgba (bgc.red, bgc.green, bgc.blue, bgc.alpha);
        ctx.set_line_width (2);

        for (var i = 0; i <= drawable.width_points; i++) {
            ctx.move_to (i * scaleable.scale, 0);
            ctx.line_to (i * scaleable.scale, height);
        }

        for (var j = 0; j <= drawable.height_points; j++) {
            ctx.move_to (0, j * scaleable.scale);
            ctx.line_to (width, j * scaleable.scale);
        }

        ctx.stroke ();
    }

    protected void draw_live_cells (Cairo.Context ctx) {
        var lcc = color_palette.live_cell_color;
        ctx.set_source_rgba (lcc.red, lcc.green, lcc.blue, lcc.alpha);

        drawable.draw (visible_drawable_rec (ctx), point => {
            var top_left = drawable_to_cairo (point);
            ctx.rectangle (top_left.x, top_left.y, scaleable.scale - 2, scaleable.scale - 2);
        });

        ctx.fill ();
    }

    protected virtual void apply_highlights (Cairo.Context ctx) {
    }

    protected Point drawable_to_cairo (Point drawable_point) {
        return drawable_point.x_add (drawable.width_points / 2)
            .y_add (-drawable.height_points / 2 + 1)
            .flip_h ()
            .scale (scaleable.scale);
    }

    protected Point cairo_to_drawable (Point cairo_point) {
        return cairo_point
            .scale_imprecise (reverse_scale)
            .flip_h ()
            .y_add (drawable.height_points / 2 - 1)
            .x_add (-drawable.width_points / 2);
    }

    protected Rectangle visible_drawable_rec (Cairo.Context ctx) {
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
}
