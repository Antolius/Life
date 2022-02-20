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

// because of consecutive dots:
// vala-lint=skip-file
namespace Life.HashLife.SimulationTests {

    public void add_funcs () {
        Test.add_func ("/HashLife/Simulation/horizontal_blinker", test_horizontal_blinker);
        Test.add_func ("/HashLife/Simulation/vertical_blinker", test_vertical_blinker);
        Test.add_func ("/HashLife/Simulation/glider", test_glider);
    }

    void test_horizontal_blinker () {
        var factory = new QuadFactory ();
        var tree = new QuadTree (2, factory);
        var simulation = new Simulation (tree, factory);
        assert (tree.root.width == 4);
        string[] given_starting_blinker_pattern = {
            "....",
            ".O..",
            ".O..",
            ".O.."
        };

        load_plaintext_pattern (tree, given_starting_blinker_pattern);
        simulation.step ();

        string[] expected_stepped_blinker_pattern = {
            "................",
            "................",
            "................",
            "................",
            "................",
            "................",
            "................",
            "................",
            "......OOO.......",
            "................",
            "................",
            "................",
            "................",
            "................",
            "................",
            "................"
        };
        assert_tree_contains_pattern (tree, expected_stepped_blinker_pattern);
    }

    void test_vertical_blinker () {
        var factory = new QuadFactory ();
        var tree = new QuadTree (2, factory);
        var simulation = new Simulation (tree, factory);
        assert (tree.root.width == 4);
        string[] given_starting_blinker_pattern = {
            "....",
            "....",
            ".OOO",
            "...."
        };

        load_plaintext_pattern (tree, given_starting_blinker_pattern);
        simulation.step ();

        string[] expected_stepped_blinker_pattern = {
            "................",
            "................",
            "................",
            "................",
            "................",
            "................",
            "................",
            "........O.......",
            "........O.......",
            "........O.......",
            "................",
            "................",
            "................",
            "................",
            "................",
            "................"
        };
        assert_tree_contains_pattern (tree, expected_stepped_blinker_pattern);
    }

    void test_glider () {
        var factory = new QuadFactory ();
        var tree = new QuadTree (4, factory);
        var simulation = new Simulation (tree, factory);
        assert (tree.root.width == 16);
        string[] glider_1_pattern = {
            "................",
            "................",
            "................",
            "................",
            "................",
            "................",
            ".......O........",
            "........O.......",
            "......OOO.......",
            "................",
            "................",
            "................",
            "................",
            "................",
            "................",
            "................"
        };

        load_plaintext_pattern (tree, glider_1_pattern);
        simulation.step ();

        string[] glider_2_step = {
            "................",
            "................",
            "................",
            "................",
            "................",
            "................",
            "................",
            "......O.O.......",
            ".......OO.......",
            ".......O........",
            "................",
            "................",
            "................",
            "................",
            "................",
            "................"
        };
        assert_tree_contains_pattern (tree, glider_2_step);

        simulation.step ();

        string[] glider_3_step = {
            "................",
            "................",
            "................",
            "................",
            "................",
            "................",
            "................",
            "........O.......",
            "......O.O.......",
            ".......OO.......",
            "................",
            "................",
            "................",
            "................",
            "................",
            "................"
        };
        assert_tree_contains_pattern (tree, glider_3_step);

        simulation.step ();

        string[] glider_4_step = {
            "................",
            "................",
            "................",
            "................",
            "................",
            "................",
            "................",
            ".......O........",
            "........OO......",
            ".......OO.......",
            "................",
            "................",
            "................",
            "................",
            "................",
            "................"
        };
        assert_tree_contains_pattern (tree, glider_4_step);

        simulation.step ();

        string[] glider_5_step = {
            "................",
            "................",
            "................",
            "................",
            "................",
            "................",
            "................",
            "........O.......",
            ".........O......",
            ".......OOO......",
            "................",
            "................",
            "................",
            "................",
            "................",
            "................"
        };
        assert_tree_contains_pattern (tree, glider_5_step);
    }
}
