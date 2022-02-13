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

public class Life.MainWindow : Hdy.ApplicationWindow {

    private Gtk.Grid grid;
    private uint configure_id;

    public MainWindow (Application application) {
        Object (
            application: application,
            title: Constants.SIMPLE_NAME
        );
    }

    static construct {
        load_style ();
    }

    private static void load_style () {
        var provider = new Gtk.CssProvider ();
        var resource_name = Life.Constants.resource_base () + "/style.css";
        provider.load_from_resource (resource_name);
        var screen = Gdk.Screen.get_default ();
        Gtk.StyleContext.add_provider_for_screen (
            screen,
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }

    construct {
        apply_saved_window_state ();
        create_layout ();
        show_all ();
    }

    private void apply_saved_window_state () {
        int window_x, window_y;
        var rect = Gtk.Allocation ();

        Application.settings.get ("window-position", "(ii)", out window_x, out window_y);
        Application.settings.get ("window-size", "(ii)", out rect.width, out rect.height);

        if (window_x != -1 || window_y != -1) {
            move (window_x, window_y);
        }

        set_allocation (rect);

        if (Application.settings.get_boolean ("window-maximized")) {
            maximize ();
        }
    }

    public override bool configure_event (Gdk.EventConfigure event) {
        if (configure_id != 0) {
            GLib.Source.remove (configure_id);
        }

        configure_id = Timeout.add (100, () => {
            configure_id = 0;

            if (is_maximized) {
                Application.settings.set_boolean ("window-maximized", true);
            } else {
                Application.settings.set_boolean ("window-maximized", false);

                Gdk.Rectangle rect;
                get_allocation (out rect);
                Application.settings.set ("window-size", "(ii)", rect.width, rect.height);

                int root_x, root_y;
                get_position (out root_x, out root_y);
                Application.settings.set ("window-position", "(ii)", root_x, root_y);
            }

            return false;
        });

        return base.configure_event (event);
    }

    private void create_layout () {
        grid = new Gtk.Grid ();

        var header_bar = new Widgets.HeaderBar ();
        grid.attach (header_bar, 0, 0);

        var scrolled_area = new Gtk.ScrolledWindow (null, null) {
            child = new Widgets.DrawingBoard (tree_with_a_glider ())
        };
        grid.attach (scrolled_area, 0, 1);

        child = grid;
    }

    private HashLife.QuadTree tree_with_a_glider () {
        var tree = new HashLife.QuadTree (6);
        var corner = new Point (-tree.root.width / 2, tree.root.width / 2 - 1);
        tree.set_alive (corner.x_add (2).y_add (-1), true);
        tree.set_alive (corner.x_add (3).y_add (-2), true);
        tree.set_alive (corner.x_add (1).y_add (-3), true);
        tree.set_alive (corner.x_add (2).y_add (-3), true);
        tree.set_alive (corner.x_add (3).y_add (-3), true);
        return tree;
    }
}
