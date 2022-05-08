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


    public SimulationPane (State state) {
        Object (
            state: state
        );
    }

    construct {
        var board = new Widgets.DrawingBoard (state);
        var scrolled_board = new Widgets.ScrolledBoard (board);
        var board_overlay = new Gtk.Overlay () {
            child = scrolled_board
        };
        var stats = new Widgets.StatsOverlay (state);
        board_overlay.add_overlay (stats);
        board_overlay.set_overlay_pass_through (stats, true);
        attach (board_overlay, 0, 0);

        var playback_bar = new Widgets.PlaybackBar (state);
        attach (playback_bar, 0, 1);
    }

}
