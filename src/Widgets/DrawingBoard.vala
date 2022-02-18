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

    private const int DEFAULT_SCALE = 10; // 1 tree point == 10 pixels

    public Drawable drawable { get; construct; }
    public int scale { get; construct; }
    public ColorPalette color_palette { get; construct; }
    // TODO: think hard about these casts:
    public int width { get { return (int) drawable.width_points * scale; } }
    public int height { get { return (int) drawable.height_points * scale; } }
    public double reverse_scale { get { return 1 / ((double) scale); } }

    public DrawingBoard (Drawable drawable) {
        Object (
            drawable: drawable,
            scale: DEFAULT_SCALE,
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
    }

    private bool on_draw (Cairo.Context ctx) {
        reset_background (ctx);
        draw_grid (ctx);
        draw_live_cells (ctx);
        return false;
    }

    private void reset_background (Cairo.Context ctx) {
        var dcc = color_palette.dead_cell_color;
        ctx.set_source_rgba (dcc.red, dcc.blue, dcc.green, dcc.alpha);
        ctx.rectangle (0, 0, width, height);
        ctx.fill ();
    }

    private void draw_grid (Cairo.Context ctx) {
        var bgc = color_palette.background_color;
        ctx.set_source_rgba (bgc.red, bgc.blue, bgc.green, bgc.alpha);
        ctx.set_line_width (2);

        for (var i = 0; i <= drawable.width_points; i++) {
            ctx.move_to (i * scale, 0);
            ctx.line_to (i * scale, height);
        }

        for (var j = 0; j <= drawable.height_points; j++) {
            ctx.move_to (0, j * scale);
            ctx.line_to (width, j * scale);
        }

        ctx.stroke ();
    }

    private void draw_live_cells (Cairo.Context ctx) {
        var lcc = color_palette.live_cell_color;
        ctx.set_source_rgba (lcc.red, lcc.blue, lcc.green, lcc.alpha);

        drawable.draw (visible_drawable_rec (ctx), point => {
            var top_left = drawable_to_cairo (point);
            ctx.rectangle (top_left.x, top_left.y, scale - 2, scale - 2);
        });

        ctx.fill ();
    }

    private Point drawable_to_cairo (Point drawable_point) {
        return drawable_point.x_add (drawable.width_points / 2)
            .y_add (-drawable.height_points / 2 + 1)
            .flip_h ()
            .scale (scale)
            .add (1);
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
}
