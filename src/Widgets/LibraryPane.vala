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

public class Life.Widgets.LibraryPane : Gtk.ScrolledWindow {

    public State state { get; construct; }

    private ListStore patterns_store = new ListStore (typeof (Pattern));

    public LibraryPane (State state) {
        Object (
            state: state
        );
    }

    construct {
        var content = new Gtk.Grid ();
        var label = new Gtk.Label (_("Patterns Library"));
        label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
        content.attach (label, 0, 0);

        var list_box = new Gtk.ListBox () {
            selection_mode = Gtk.SelectionMode.NONE,
            hexpand = true
        };
        list_box.bind_model (patterns_store, create_row);
        list_box.get_style_context ().add_class ("library");
        content.attach (list_box, 0, 1);

        child = content;

        load_library.begin ();
    }

    private async void load_library () {
        try {
            var no_flags = ResourceLookupFlags.NONE;
            var patterns_path = "/" + Constants.resource_base () + "/patterns";
            var files = resources_enumerate_children (patterns_path, no_flags);

            var patterns = new Gee.ArrayList<Pattern> ();
            foreach (var file_name in files) {
                var path = patterns_path + "/" + file_name;
                var input = resources_open_stream (path, no_flags);
                var pattern = yield Pattern.from_plaintext (input);
                patterns.add (pattern);
            }
            patterns.sort ((p1, p2) => {
                var a1 = p1.width_points * p1.height_points;
                var a2 = p2.width_points * p2.height_points;
                return (int) (a1 - a2);
            });

            foreach (var pattern in patterns) {
                patterns_store.append (pattern);
            }
        } catch (Error err) {
            warning (
                "Failed to load patterns library from resource file, %s",
                print_err (err)
            );
            Idle.add (load_library.callback);
            yield;
            state.info (new Life.InfoModel (
                _("Failed to load the patterns library"),
                Gtk.MessageType.ERROR,
                _("Retry loading"),
                () => load_library.begin ()
            ));
        }
    }

    private Gtk.ListBoxRow create_row (Object element) {
        var pattern = (Pattern) element;
        return new PatternLibraryRow (pattern, state);
    }

    private string print_err (Error err) {
        var format = "Error Message: \"%s\", Error code: %d, Error domain: %";
        format += uint32.FORMAT;
        return (format).printf (
            err.message,
            err.code,
            err.domain
        );
    }
}
