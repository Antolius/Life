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

public class Life.ColorPalette : Object {

    private Gtk.StyleContext? background_style = null;
    private Gtk.StyleContext? cell_style = null;

    private Gdk.RGBA? _background_color = null;
    public Gdk.RGBA? background_color { get {
        if (_background_color == null) {
            setup_colors ();
        }

        return _background_color;
    } }

    private Gdk.RGBA? _dead_cell_color = null;
    public Gdk.RGBA? dead_cell_color { get {
        if (_dead_cell_color == null) {
            setup_colors ();
        }

        return _dead_cell_color;
    } }

    private Gdk.RGBA? _live_cell_color = null;
    public Gdk.RGBA? live_cell_color { get {
        if (_live_cell_color == null) {
            setup_colors ();
        }

        return _live_cell_color;
    } }

    private void setup_colors () {
        if (background_style == null || cell_style == null) {
            setup_styles ();
        }

        update_changed_colors ();
    }

    private void setup_styles () {
        var window_widget_path = new Gtk.WidgetPath ();
        window_widget_path.append_type (typeof (Gtk.Window));
        window_widget_path.iter_set_object_name (1, "window");
        window_widget_path.iter_add_class (1, "background");

        background_style = new Gtk.StyleContext ();
        background_style.set_path (window_widget_path);
        background_style.changed.connect (update_changed_colors);

        var label_widget_path = new Gtk.WidgetPath ();
        label_widget_path.append_type (typeof (Gtk.Button));
        label_widget_path.iter_set_object_name (1, "button");

        cell_style = new Gtk.StyleContext ();
        cell_style.set_path (label_widget_path);
        cell_style.changed.connect (update_changed_colors);
    }

    private void update_changed_colors () {
        var color = extract_background_color ();
        if (color != _background_color) {
            _background_color = color;
        }

        color = extract_dead_cell_color ();
        if (color != _dead_cell_color) {
            _dead_cell_color = color;
        }

        color = extract_live_cell_color ();
        if (color != _live_cell_color) {
            _live_cell_color = color;
        }
    }

    private Gdk.RGBA extract_background_color () {
        return (Gdk.RGBA) background_style.get_property (
            Gtk.STYLE_PROPERTY_BACKGROUND_COLOR,
            Gtk.StateFlags.ACTIVE
        );
    }

    private Gdk.RGBA extract_dead_cell_color () {
        return (Gdk.RGBA) cell_style.get_property (
            Gtk.STYLE_PROPERTY_BACKGROUND_COLOR,
            Gtk.StateFlags.INSENSITIVE
        );
    }

    private Gdk.RGBA extract_live_cell_color () {
        return (Gdk.RGBA) cell_style.get_property (
            Gtk.STYLE_PROPERTY_COLOR,
            Gtk.StateFlags.INSENSITIVE
        );
    }
}
