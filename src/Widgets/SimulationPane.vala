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

public class Life.Widgets.SimulationPane : Gtk.Grid {

    public State state { get; construct; }
    private ulong? infobar_response_handler_id;

    public SimulationPane (State state) {
        Object (
            state: state
        );
    }

    construct {
        var infobar = new Gtk.InfoBar () {
            show_close_button = true,
            revealed = false
        };
        state.info.connect (model => {
            update_infobar (infobar, model);
        });
        attach (infobar, 0, 0);

        var board = new Widgets.EditingBoard (state);
        state.simulation_updated.connect_after (() => {
            board.queue_resize ();
            board.queue_draw ();
        });

        var scrolled_board = new Widgets.ScrolledBoard (board);
        var board_overlay = new Gtk.Overlay () {
            child = scrolled_board
        };
        var stats = new Widgets.StatsOverlay (state);
        board_overlay.add_overlay (stats);
        board_overlay.set_overlay_pass_through (stats, true);
        attach (board_overlay, 0, 1);

        var playback_bar = new Widgets.PlaybackBar (state);
        attach (playback_bar, 0, 2);
    }

    private void update_infobar (Gtk.InfoBar infobar, InfoModel model) {
        var content = infobar.get_content_area ();
        foreach (var widget in content.get_children ()) {
            content.remove (widget);
        }
        content.child = new Gtk.Label (model.message);

        infobar.message_type = model.message_type;

        var actions = infobar.get_action_area ();
        foreach (var widget in actions.get_children ()) {
            actions.remove (widget);
        }

        if (infobar_response_handler_id != null) {
            infobar.disconnect (infobar_response_handler_id);
            infobar_response_handler_id = null;
        }

        if (model.action_label != null && model.action_handler != null) {
            infobar.add_button (model.action_label, 1);

            infobar_response_handler_id = infobar.response.connect (id => {
                infobar.revealed = false;

                if (id == 1) {
                    model.action_handler ();
                }
            });
        }

        infobar.show_all ();
        infobar.revealed = true;
    }
}
