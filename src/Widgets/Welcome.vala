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
        var group = get_action_group (WIN_GROUP);
        assert (group != null);
        group.activate_action (ACTION_OPEN_AUTOSAVE, null);
    }

    private void open_file () {
        var group = get_action_group (WIN_GROUP);
        assert (group != null);
        group.activate_action (ACTION_OPEN_FILE, null);
    }
}
