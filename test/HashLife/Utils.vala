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

namespace Life.HashLife {
    public void load_plaintext_pattern (HashLife.QuadTree tree, string[] rows) {
        var width = tree.root.width;
        for (var i = 0; i < width; i++) {
            for (var j = 0; j < width; j++) {
                var cell_is_alive = rows[j].data[i] == 'O';
                var p = new Point (i, j).flip ().add (width / 2 - 1);
                tree.set_alive (p, cell_is_alive);
            }
        }
    }

    public void assert_tree_contains_pattern (
        QuadTree actual_tree,
        string[] expected_rows
    ) {
        var width = actual_tree.root.width;
        print ("Expected width: %d, actual width: %d\n", expected_rows.length, (int) width);
        assert (width == expected_rows.length);

        var output_captor = new string[width];
        for (var i = 0; i < width; i++) {
            var row = "";
            for (var j = 0; j < width; j++) {
                row += ".";
            }
            output_captor[i] = row;
        }

        actual_tree.draw_entire ((p) => {
            var ap = p.add (-width / 2 + 1).flip ();
            output_captor [ap.y].data[ap.x] = 'O';
        });

        print ("Expected:\n");
        print_plaintext_pattern (expected_rows);
        print ("\nActual:\n");
        print_plaintext_pattern (output_captor);
        print ("\n\n");

        for (var i = 0; i < width; i++) {
            assert (expected_rows[i] == output_captor[i]);
        }
    }

    public void print_plaintext_pattern (string[] rows) {
        foreach (var row in rows) {
            print ("%s\n", row);
        }
    }
}
