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

public class Life.Widgets.BoardGrid : Gtk.Grid {

    public Simulation sim { get; construct; }

    public BoardGrid (Simulation simulation) {
        Object (
            sim: simulation,
            column_homogeneous: true,
            column_spacing: 2,
            row_homogeneous: true,
            row_spacing: 2,
            hexpand: true,
            vexpand: true,
            halign: Gtk.Align.CENTER,
            valign: Gtk.Align.CENTER
        );
    }

    construct {
        connect_listeners ();
        render_grid ();
    }

    private void connect_listeners () {
        sim.notify["grid"].connect (render_grid);
    }

    private void render_grid () {
        clear_grid ();

        for (int left = 0; left < sim.max_width; left++) {
            for (int top = sim.max_height - 1; top >= 0; top--) {
                var is_alive = sim.grid[left][top];
                var cell = cell_for (is_alive);
                attach (cell, left, top);
            }
        }

        show_all ();
    }

    private void clear_grid () {
        @foreach (child => child.destroy ());
    }

    private Gtk.Widget cell_for (bool is_alive) {
        var square = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            height_request = 8,
            width_request = 8,
        };

        var css_class = is_alive ? "live-cell" : "dead-cell";
        square.get_style_context ().add_class (css_class);

        return square;
    }
}
