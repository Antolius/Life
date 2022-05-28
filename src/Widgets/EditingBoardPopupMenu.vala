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

public class Life.Widgets.EditingBoardPopupMenu : Gtk.Menu {

    public State state { get; construct; }
    public Point drawable_click_point { get; construct; }
    public Gee.List<Rectangle> select_rects { get; construct; }

    public signal void drawable_updated ();

    public EditingBoardPopupMenu (
        State state,
        Point drawable_click_point,
        Gee.List<Rectangle> select_rects
    ) {
        Object (
            state: state,
            drawable_click_point: drawable_click_point,
            select_rects: select_rects
        );
    }

    construct {
        var selection_exists = !select_rects.is_empty;
        var fill_label = _("Fill Selection with Live Cells");
        var fill_item = create_item (
            _("Fill Selection with Live Cells"),
            selection_exists
        );
        fill_item.activate.connect (fill_selection);
        append (fill_item);

        var clear_item = create_item (
            _("Clear Selected Cells"),
            selection_exists
        );
        clear_item.activate.connect (clear_selection);
        append (clear_item);

        append (new Gtk.SeparatorMenuItem ());

        var copy_item = create_item (
            _("Copy Selection"),
            selection_exists
        );
        copy_item.activate.connect (copy_selection);
        append (copy_item);

        var paste_item = create_item (
            _("Paste"),
            true // TODO: check if copy buffer is full
        );
        paste_item.activate.connect (paste_selection);
        append (paste_item);

        append (new Gtk.SeparatorMenuItem ());

        var flip_horizontally_item = create_item_with_icon (
            "object-flip-horizontal-symbolic",
            _("Flip Horizontally"),
            selection_exists
        );
        flip_horizontally_item.activate.connect (flip_horizontally);
        append (flip_horizontally_item);

        var flip_vertically_item = create_item_with_icon (
            "object-flip-vertical-symbolic",
            _("Flip Vertically"),
            selection_exists
        );
        flip_vertically_item.activate.connect (flip_vertically);
        append (flip_vertically_item);

        var rotate_clockwise_item = create_item_with_icon (
            "object-rotate-right-symbolic",
            _("Rotate Clockwise"),
            selection_exists
        );
        rotate_clockwise_item.activate.connect (rotate_clockwise);
        append (rotate_clockwise_item);

        var rotate_counter_clockwise_item = create_item_with_icon (
            "object-rotate-left-symbolic",
            _("Rotate Counter-Clockwise"),
            selection_exists
        );
        rotate_counter_clockwise_item.activate.connect (rotate_counter_clockwise);
        append (rotate_counter_clockwise_item);


        show_all ();
    }

    private Gtk.MenuItem create_item (string label_txt, bool is_sensitive) {
        return new Gtk.MenuItem.with_label (label_txt) {
            sensitive = is_sensitive
        };
    }

    private Gtk.MenuItem create_item_with_icon (
        string icon_name,
        string label_txt,
        bool is_sensitive
    ) {
        var content = new Gtk.Box (
            Gtk.Orientation.HORIZONTAL, 8
        );
        var icon = new Gtk.Image () {
            gicon = new ThemedIcon (icon_name),
            pixel_size = 16
        };
        content.add (icon);
        var label = new Gtk.Label (label_txt);
        content.add (label);
        var menu_item = new Gtk.MenuItem () {
            sensitive = is_sensitive
        };
        menu_item.add (content);
        return menu_item;
    }

    private void fill_selection () {
        foreach (var select in select_rects) {
            fill_rect (select, true);
        }

        drawable_updated ();
    }

    private void clear_selection () {
        foreach (var select in select_rects) {
            fill_rect (select, false);
        }

        drawable_updated ();
    }

    private void copy_selection () {
        // TODO: implement
    }

    private void paste_selection () {
        // TODO: implement
    }

    private void flip_horizontally () {
        var shapes = extract_selected_shapes ();
        for (var i = 0; i < shapes.size; i++) {
            var select = select_rects[i];
            var shape = shapes[i];

            shape.flip_horizontally ();
            draw_shape_at_point (select.center (), shape);
        }

        drawable_updated ();
    }

    private void flip_vertically () {
        var shapes = extract_selected_shapes ();
        for (var i = 0; i < shapes.size; i++) {
            var select = select_rects[i];
            var shape = shapes[i];

            shape.flip_vertically ();
            draw_shape_at_point (select.center (), shape);
        }

        drawable_updated ();
    }

    private void rotate_clockwise () {
        var shapes = extract_selected_shapes ();
        for (var i = 0; i < shapes.size; i++) {
            var select = select_rects[i];
            var shape = shapes[i];

            shape.rotate_clockwise ();
            fill_rect (select, false);
            draw_shape_at_point (select.center (), shape, false);
        }

        drawable_updated ();
    }

    private void rotate_counter_clockwise () {
        var shapes = extract_selected_shapes ();
        for (var i = 0; i < shapes.size; i++) {
            var select = select_rects[i];
            var shape = shapes[i];

            shape.rotate_counter_clockwise ();
            fill_rect (select, false);
            draw_shape_at_point (select.center (), shape, false);
        }

        drawable_updated ();
    }

    private Gee.List<Shape> extract_selected_shapes () {
        var drawable = state.drawable;
        var shapes = new Gee.LinkedList<Shape> ();

        foreach (var select in select_rects) {
            shapes.add (new CutoutShape (select, drawable));
        }

        return shapes;
    }

    private void fill_rect (Rectangle rect, bool alive) {
        var bottom_left = rect.bottom_left;
        var top_rigth = rect.top_rigth ();
        for (var x = bottom_left.x; x < top_rigth.x; x++) {
            for (var y = bottom_left.y; y < top_rigth.y; y++) {
                state.editable.set_alive (new Point (x, y), alive);
            }
        }
    }

    private void draw_shape_at_point (
        Point center_point,
        Shape shape,
        bool override_with_dead_cells = true
    ) {
        var editable = state.editable;
        shape.write_into (editable, center_point, override_with_dead_cells);
    }
}
