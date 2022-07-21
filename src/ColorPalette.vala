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

    public signal void changed ();

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

    private Gdk.RGBA? _accent_color = null;
    public Gdk.RGBA? accent_color { get {
        if (_accent_color == null) {
            setup_colors ();
        }

        return _accent_color;
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
        window_widget_path.iter_set_state (1, Gtk.StateFlags.DIR_LTR);

        background_style = new Gtk.StyleContext ();
        background_style.set_path (window_widget_path);
        background_style.changed.connect (() => {
            update_changed_colors ();
            changed ();
        });

        var button_widget_path = new Gtk.WidgetPath ();
        button_widget_path.append_type (typeof (Gtk.Button));
        button_widget_path.iter_set_object_name (1, "button");

        cell_style = new Gtk.StyleContext ();
        cell_style.set_path (button_widget_path);
        cell_style.changed.connect (() => {
            update_changed_colors ();
            changed ();
        });
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

        color = extract_accent_color ();
        if (color != _accent_color) {
            _accent_color = color;
        }
    }

    private Gdk.RGBA extract_background_color () {
        var rgba = (Gdk.RGBA) background_style.get_property (
            Gtk.STYLE_PROPERTY_BACKGROUND_COLOR,
            Gtk.StateFlags.DIR_LTR
        );
        return rgba;
    }

    private Gdk.RGBA extract_dead_cell_color () {
         cell_style.save ();
         var rgba = (Gdk.RGBA) cell_style.get_property (
             Gtk.STYLE_PROPERTY_BACKGROUND_COLOR,
             Gtk.StateFlags.INSENSITIVE
         );
         cell_style.restore ();
         return rgba;
    }

    private Gdk.RGBA extract_live_cell_color () {
         cell_style.save ();
         var rgba = (Gdk.RGBA) cell_style.get_property (
             Gtk.STYLE_PROPERTY_COLOR,
             Gtk.StateFlags.INSENSITIVE
         );
         cell_style.restore ();
         return rgba;
    }

    private Gdk.RGBA extract_accent_color () {
         cell_style.save ();
         var rgba = (Gdk.RGBA) cell_style.get_property (
             Gtk.STYLE_PROPERTY_COLOR,
             Gtk.StateFlags.LINK
         );
         cell_style.restore ();
         return rgba;
    }
}
