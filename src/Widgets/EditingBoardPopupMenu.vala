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

    public const Gtk.TargetEntry[] TARGET_ENTRIES = {
        {Constants.SHAPES, Gtk.TargetFlags.SAME_APP | Gtk.TargetFlags.OTHER_WIDGET, 0}
    };

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

        var copy_item = create_item (_("Copy"), selection_exists);
        copy_item.activate.connect (copy_selection);
        append (copy_item);

        var cut_item = create_item (_("Cut"), selection_exists);
        cut_item.activate.connect (cut_selection);
        append (cut_item);

        var atom = Gdk.Atom.intern_static_string (Constants.SHAPES);
        var clipboard_full = state.clipboard.wait_is_target_available (atom);
        var paste_item = create_item (_("Paste"), clipboard_full);
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
        copy_to_clipboard (extract_shape_selections ());
    }

    private void cut_selection () {
        var shape_selections = extract_shape_selections ();
        var copy_succeeded = copy_to_clipboard (shape_selections);
        if (copy_succeeded) {
            foreach (var shape_select in shape_selections) {
                fill_rect (shape_select.select, false);
            }
        }
    }

    private bool copy_to_clipboard (Gee.List<ShapeSelection> shape_selections) {
        Gee.List<ShapeSelection>* pointer = new Gee.LinkedList<ShapeSelection> ();
        foreach (var shape in shape_selections) {
            pointer->add (shape);
        }

        var copy_succeeded = state.clipboard.set_with_data (
            TARGET_ENTRIES,
            (_clipboard, selection_data, info, _pointer) => {
                var shapes_ptr = (Gee.List<ShapeSelection>*) _pointer;
                var shapes_data = new uint8[(sizeof (Gee.List<ShapeSelection>))];
                ((Gee.List<ShapeSelection>[])shapes_data)[0] = shapes_ptr;
                var atom = Gdk.Atom.intern_static_string (Constants.SHAPES);
                selection_data.set (atom, 0, shapes_data);
            },
            (_clipboard, _pointer) => {
                delete (Gee.List<ShapeSelection>*) _pointer;
            },
            pointer
        );

        if (!copy_succeeded) {
            warning ("Copy failed!");
        }

        return copy_succeeded;
    }

    private void paste_selection () {
        var atom = Gdk.Atom.intern_static_string (Constants.SHAPES);
        var data = state.clipboard.wait_for_contents (atom);
        if (data == null) {
            warning ("Could not find shapes in clipboard!");
            return;
        }

        var shape_selections = ((Gee.List<ShapeSelection>[]) data.get_data ())[0];
        var min_x = int.MAX;
        var min_y = int.MAX;
        var max_x = int.MIN;
        var max_y = int.MIN;
        foreach (var shape_select in shape_selections) {
            var select = shape_select.select;
            min_x = int.min (min_x, (int) select.bottom_left.x);
            min_y = int.min (min_y, (int) select.bottom_left.y);
            max_x = int.max (max_x, (int) select.top_rigth ().x);
            max_y = int.max (max_y, (int) select.top_rigth ().y);
        }
        var dif_x = drawable_click_point.x - min_x - ((max_x - min_x) / 2);
        var dif_y = drawable_click_point.y - min_y - ((max_y - min_y) / 2);

        foreach (var shape_select in shape_selections) {
            var center = shape_select.select.center ()
                .x_add (dif_x)
                .y_add (dif_y);
            draw_shape_at_point (center, shape_select.shape);
        }

        drawable_updated ();
    }

    private void flip_horizontally () {
        var shape_selections = extract_shape_selections ();
        foreach (var shape_select in shape_selections) {
            shape_select.shape.flip_horizontally ();
            var center = shape_select.select.center ();
            draw_shape_at_point (center, shape_select.shape);
        }

        drawable_updated ();
    }

    private void flip_vertically () {
        var shape_selections = extract_shape_selections ();
        foreach (var shape_select in shape_selections) {
            shape_select.shape.flip_vertically ();
            var center = shape_select.select.center ();
            draw_shape_at_point (center, shape_select.shape);
        }

        drawable_updated ();
    }

    private void rotate_clockwise () {
        var shape_selections = extract_shape_selections ();
        foreach (var shape_select in shape_selections) {
            shape_select.shape.rotate_clockwise ();
            fill_rect (shape_select.select, false);
            var center = shape_select.select.center ();
            draw_shape_at_point (center, shape_select.shape, false);
        }

        drawable_updated ();
    }

    private void rotate_counter_clockwise () {
        var shape_selections = extract_shape_selections ();
        foreach (var shape_select in shape_selections) {
            shape_select.shape.rotate_counter_clockwise ();
            fill_rect (shape_select.select, false);
            var center = shape_select.select.center ();
            draw_shape_at_point (center, shape_select.shape, false);
        }

        drawable_updated ();
    }

    private Gee.List<ShapeSelection> extract_shape_selections () {
        var drawable = state.drawable;
        var shape_selections = new Gee.LinkedList<ShapeSelection> ();

        foreach (var select in select_rects) {
            var shape = new CutoutShape (select, drawable);
            shape_selections.add (new ShapeSelection (select, shape));
        }

        return shape_selections;
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
        shape.write_into.begin (editable, center_point, override_with_dead_cells);
    }
}

private class Life.Widgets.ShapeSelection : Object {
    public Rectangle select { get; construct; }
    public Shape shape { get; construct; }

    public ShapeSelection (Rectangle select, Shape shape) {
        Object (select: select, shape: shape);
    }
}
