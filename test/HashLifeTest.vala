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

    void test_create_empty () {
        var tree = new QuadTree ();
        assert (tree != null);
        assert (tree.root != null);
        assert (tree.root.level == 1);
    }

    void test_set_and_get () {
        var tree = new QuadTree ();
        var point = new Point (0, 0);
        assert (tree.is_alive (point) == false);
        tree.set_alive (point, true);
        assert (tree.is_alive (point) == true);
    }

    void test_fill_entire () {
        var tree = new QuadTree (2);

        for (int i = -2; i <= 1; i++) {
            for (int j = -2; j <= 1; j++) {
                tree.set_alive (new Point (i, j), true);
            }
        }

        for (int i = -2; i <= 1; i++) {
            for (int j = -2; j <= 1; j++) {
                var p = new Point (i, j);
                assert (tree.is_alive (p) == true);
            }
        }
    }

    void test_draw () {
        var tree = new QuadTree (3);
        assert (tree.root.width == 8);
        string[] glider_in_a_box = {
            "OOOOOOOO",
            "O......O",
            "O......O",
            "O..O...O",
            "O...O..O",
            "O.OOO..O",
            "O......O",
            "OOOOOOOO"
        };

        load_plaintext_pattern (tree, glider_in_a_box);
        print_plaintext_pattern (glider_in_a_box);

        string[] output_captor = {
            "........",
            "........",
            "........",
            "........",
            "........",
            "........",
            "........",
            "........"
        };

        var width = tree.root.width;
        tree.draw_entire ((p) => {
            var ap = p.add (-width / 2 + 1).flip ();
            output_captor [ap.y].data[ap.x] = 'O';
        });

        print_plaintext_pattern (output_captor);
        for (int i = 0; i < width; i++) {
            assert (glider_in_a_box[i] == output_captor[i]);
        }
    }

    void main (string[] args) {
        Test.init (ref args);
        Test.add_func ("/HashLife/QuadTree/create_empty", test_create_empty);
        Test.add_func ("/HashLife/QuadTree/set_and_get", test_set_and_get);
        Test.add_func ("/HashLife/QuadTree/fill_entire", test_fill_entire);
        Test.add_func ("/HashLife/QuadTree/draw", test_draw);
        Test.run ();
    }

    private void load_plaintext_pattern (QuadTree tree, string[] rows) {
        var width = tree.root.width;
        for (var i = 0; i < width; i++) {
            for (var j = 0; j < width; j++) {
                var cell_is_alive = rows[j].data[i] == 'O';
                var p = new Point (i, j).flip ().add (width / 2 - 1);
                tree.set_alive (p, cell_is_alive);
            }
        }
    }

    private void print_plaintext_pattern (string[] rows) {
        foreach (var row in rows) {
            print ("%s\n", row);
        }
    }
}
