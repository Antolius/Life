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

public class Life.Widgets.Welcome : Granite.Widgets.Welcome {

    public State state { get; construct; }

    public Welcome (State state) {
        Object (
            state: state,
            title: _("No Patterns Open"),
            subtitle: _("Create or import a pattern to start the simulation.")
        );
    }

    construct {
        append (
            "help-contents",
            _("Learn the Basics"),
            _("Learn the rules of Conway's Game of Life.")
        );
        append (
            "document-new",
            _("New Pattern"),
            _("Create a new empty pattern.")
        );
        if (state.autosave_exists) {
            append (
                "document-revert",
                _("Load Autosave"),
                _("Continue editing the last opened pattern.")
            );
        }
        append (
            "document-open",
            _("Open File"),
            _("Open a pattern from a saved file.")
        );

        activated.connect (handle_activation);
    }

    private void handle_activation (int index) {
        if (index == 0) {
            var dialog = new OnboardingDialog ();
            dialog.run ();
            dialog.destroy ();
            state.clear ();
            state.showing_welcome = false;
        } else if (index == 1) {
            state.clear ();
            state.showing_welcome = false;
        } else if (index == 2 && state.autosave_exists) {
            open_autosave ();
        } else if (
            (index == 3 && state.autosave_exists)
            || (index == 2 && !state.autosave_exists)
        ) {
            open_file ();
        } else {
            assert_not_reached ();
        }
    }

    private void open_autosave () {
        state.clear ();
        state.showing_welcome = false;
        state.open_autosave.begin ((obj, res) => {
            var ok = state.open_autosave.end (res);
            if (!ok) {
                state.info (new InfoModel (
                    _("Failed to open autosave file"),
                    Gtk.MessageType.ERROR,
                    _("Try opening another file"),
                    () => open_file ()
                ));
            }
        });
    }

    private void open_file () {
        var dialog = new Gtk.FileChooserNative (
            null,
            null,
            Gtk.FileChooserAction.OPEN,
            null,
            null
        ) {
            filter = cells_filter ()
        };

        var res = dialog.run ();
        if (res == Gtk.ResponseType.ACCEPT) {
            var path = dialog.get_filename ();
            if (path == null) {
                state.info (new InfoModel (
                    _("No readable file was selected"),
                    Gtk.MessageType.WARNING,
                    _("Try opening another file"),
                    () => open_file ()
                ));
                return;
            }

            state.clear ();
            state.showing_welcome = false;
            state.open.begin (path, (obj, res) => {
                var ok = state.open.end (res);
                if (!ok) {
                    state.info (new InfoModel (
                        _("Failed to open file"),
                        Gtk.MessageType.ERROR,
                        _("Try opening another file"),
                        () => open_file ()
                    ));
                }
            });
        }
    }

    private Gtk.FileFilter cells_filter () {
        var cells_filter = new Gtk.FileFilter ();
        cells_filter.set_filter_name (_("Cells files"));
        cells_filter.add_pattern ("*.cells");
        return cells_filter;
    }
}
