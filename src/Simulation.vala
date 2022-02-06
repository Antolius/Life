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

public class Life.Simulation : Object {

    public Ticker ticker { get; construct; }
    public int max_width { get; set; }
    public int max_height { get; set; }
    public Gee.List<Gee.List<bool>> grid { get; set; }

    public Simulation (Ticker ticker) {
        Object (
            ticker: ticker,
            max_width: 64,
            max_height: 48
        );

        grid = initialize_grid ((x, y) => Random.boolean ());
    }

    construct {
        ticker.tick.connect (advance_simulation);
    }

    private Gee.List<Gee.List<bool>> initialize_grid (
        ValueProvider value_provider
    ) {
        var new_grid = new Gee.ArrayList<Gee.ArrayList<bool>> ();
        for (int i = 0; i < max_width; i++) {
            var row = new Gee.ArrayList<bool> ();
            for (int j = 0; j < max_height; j++) {
                row.add (value_provider (i, j));
            }

            new_grid.add (row);
        }

        return new_grid;
    }

    private void advance_simulation () {
        grid = initialize_grid ((x, y) => {
            var neighbours = number_of_neighbours (x, y);
            if (grid[x][y]) {
                return neighbours == 2 || neighbours == 3;
            } else {
                return neighbours == 3;
            }
        });
    }

    private int number_of_neighbours (int x, int y) {
        return 0
            + (grid[loop_x (x - 1)][loop_y (y - 1)] ? 1 : 0)
            + (grid[loop_x (x - 1)][loop_y (y)] ? 1 : 0)
            + (grid[loop_x (x - 1)][loop_y (y + 1)] ? 1 : 0)
            + (grid[loop_x (x)][loop_y (y - 1)] ? 1 : 0)
            + (grid[loop_x (x)][loop_y (y + 1)] ? 1 : 0)
            + (grid[loop_x (x + 1)][loop_y (y - 1)] ? 1 : 0)
            + (grid[loop_x (x + 1)][loop_y (y)] ? 1 : 0)
            + (grid[loop_x (x + 1)][loop_y (y + 1)] ? 1 : 0);
    }

    private int loop_x (int x) {
        return loop (x, max_width);
    }

    private int loop_y (int y) {
        return loop (y, max_height);
    }

    private int loop (int coord, int max) {
        if (coord < 0) {
            return loop (max + coord, max);
        } else if (coord >= max) {
            return loop (coord - max, max);
        } else {
            return coord;
        }
    }
}

public delegate bool Life.ValueProvider (int x, int y);
