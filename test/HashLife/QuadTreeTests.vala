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

namespace Life.HashLife.QuadTreeTests {

    public void add_funcs () {
        Test.add_func ("/HashLife/QuadTree/create_empty", test_create_empty);
        Test.add_func ("/HashLife/QuadTree/set_and_get", test_set_and_get);
        Test.add_func ("/HashLife/QuadTree/fill_entire", test_fill_entire);
        Test.add_func ("/HashLife/QuadTree/draw", test_draw);
        Test.add_func ("/HashLife/QuadTree/empty_edges", test_empty_edges);
        Test.add_func ("/HashLife/QuadTree/grow", test_grow);
    }

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
        assert_tree_contains_pattern (tree, glider_in_a_box);
    }

    void test_empty_edges () {
        var tree = new QuadTree (2);
        assert (tree.root.width == 4);

        string[] empty_edged_pattern = {
            "....",
            ".OO.",
            ".OO.",
            "...."
        };
        load_plaintext_pattern (tree, empty_edged_pattern);
        var empty_edges = tree.has_empty_edges ();
        assert (empty_edges == true);

        string[] non_empty_edged_pattern = {
            "....",
            "....",
            "....",
            "O..."
        };
        load_plaintext_pattern (tree, non_empty_edged_pattern);
        empty_edges = tree.has_empty_edges ();
        assert (empty_edges == false);
    }

    void test_grow () {
        var tree = new QuadTree (2);
        assert (tree.root.width == 4);

        string[] checkers_pattern = {
            "O.O.",
            ".O.O",
            "O.O.",
            ".O.O"
        };
        load_plaintext_pattern (tree, checkers_pattern);

        tree.grow ();

        string[] expected_pattenr = {
            "........",
            "........",
            "..O.O...",
            "...O.O..",
            "..O.O...",
            "...O.O..",
            "........",
            "........"
        };
        assert_tree_contains_pattern (tree, expected_pattenr);
    }
}
