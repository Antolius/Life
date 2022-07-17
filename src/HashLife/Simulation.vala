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

public class Life.HashLife.Simulation : Object, Stepper {

    public const uint32 MAX_SPEED = QuadTree.MAX_LEVEL - 2;

    public int64 generation { get; set; default = 0; }
    public QuadTree tree { get; construct; }
    public QuadFactory factory { get; construct; }

    private Cache.MonitoredCache<Pair, Quad> steps_cache;
    private Stats.Timer step_timer = new Stats.Timer () {
        name = _("Step timer"),
        description = _("Time spent in Simulation's step method.")
    };

    public Simulation (QuadTree tree, QuadFactory factory) {
        Object (
            tree: tree,
            factory: factory
        );
    }

    construct {
        steps_cache = new Cache.MonitoredCache<Pair, Quad> (
            "Steps cacne",
            new Cache.LfuCache<Pair, Quad> (
                // 1000, // < 20 MiB
                // 10000, // < 30 MiB
                100000, // < 100 MiB
                // 1000000, // < 800 MiB
                _step_quad_with_speed,
                p => p.hash,
                (p1, p2) => p1 == null && p2 == null || p1.equals (p2),
                (q1, q2) => q1 == null && q2 == null || q1.equals (q2)
            )
        );
    }

    public void step () {
        var stop_timer = step_timer.start_timer ();
        step_with_speed (0);
        stop_timer ();
    }

    // step forward 2^speed generations
    public void step_with_speed (int speed)
        requires (speed <= MAX_SPEED)
        requires (speed >= 0) {
        lock (tree) {
            grow_tree_if_necessery (speed);
            tree.root = step_quad_with_speed (tree.root, speed);
            tree.grow ();

            generation += ((int64) 1) << speed;
            step_completed ();
        }
    }

    private Quad step_quad_with_speed (Quad quad, int speed) {
        var key = new Pair (quad, speed);
        return steps_cache.access (key);
    }

    private Quad _step_quad_with_speed (Pair quad_and_speed)
        requires (quad_and_speed.first.level >= 2)
        requires (quad_and_speed.second >= 0)
        requires (quad_and_speed.second <= quad_and_speed.first.level - 2) {
        var quad = quad_and_speed.first;
        var speed = quad_and_speed.second;

        if (tree._is_empty (quad)) {
            return factory.create_empty_quad (quad.level - 1);
        }

        if (speed == 0 && quad.level == 2) {
            return step_two_quad_by_one (quad);
        }

        return recursivelly_step_quad_with_speed (quad, speed);
    }

    private Quad step_two_quad_by_one (Quad two_quad)
        requires (two_quad.level == 2)
        ensures (result.level == 1) {
        /*
            nw_nw   nw_ne   ne_nw   ne_ne
            nw_sw  *nw_se* *ne_sw*  ne_se
            sw_nw  *sw_ne* *se_nw*  se_ne
            sw_sw   sw_se   se_sw   se_se
        */

        var nw_nw = two_quad.nw.nw == QuadFactory.alive ? 1 : 0;
        var nw_ne = two_quad.nw.ne == QuadFactory.alive ? 1 : 0;
        var nw_se = two_quad.nw.se == QuadFactory.alive ? 1 : 0;
        var nw_sw = two_quad.nw.sw == QuadFactory.alive ? 1 : 0;
        var ne_nw = two_quad.ne.nw == QuadFactory.alive ? 1 : 0;
        var ne_ne = two_quad.ne.ne == QuadFactory.alive ? 1 : 0;
        var ne_se = two_quad.ne.se == QuadFactory.alive ? 1 : 0;
        var ne_sw = two_quad.ne.sw == QuadFactory.alive ? 1 : 0;
        var se_nw = two_quad.se.nw == QuadFactory.alive ? 1 : 0;
        var se_ne = two_quad.se.ne == QuadFactory.alive ? 1 : 0;
        var se_se = two_quad.se.se == QuadFactory.alive ? 1 : 0;
        var se_sw = two_quad.se.sw == QuadFactory.alive ? 1 : 0;
        var sw_nw = two_quad.sw.nw == QuadFactory.alive ? 1 : 0;
        var sw_ne = two_quad.sw.ne == QuadFactory.alive ? 1 : 0;
        var sw_se = two_quad.sw.se == QuadFactory.alive ? 1 : 0;
        var sw_sw = two_quad.sw.sw == QuadFactory.alive ? 1 : 0;

        var nw_se_count = nw_nw + nw_ne + ne_nw + ne_sw + se_nw + sw_ne + sw_nw + nw_sw;
        var ne_sw_count = nw_ne + ne_nw + ne_ne + ne_se + se_ne + se_nw + sw_ne + nw_se;
        var se_nw_count = nw_se + ne_sw + ne_se + se_ne + se_se + se_sw + sw_se + sw_ne;
        var sw_ne_count = nw_sw + nw_se + ne_sw + se_nw + se_sw + sw_se + sw_sw + sw_nw;

        return factory.create_quad (
            step_zero_quad_with_neighbours_count (two_quad.nw.se, nw_se_count),
            step_zero_quad_with_neighbours_count (two_quad.ne.sw, ne_sw_count),
            step_zero_quad_with_neighbours_count (two_quad.se.nw, se_nw_count),
            step_zero_quad_with_neighbours_count (two_quad.sw.ne, sw_ne_count)
        );
    }

    private Quad step_zero_quad_with_neighbours_count (
        Quad zero_quad,
        int number_of_live_neighbours
    )
        requires (zero_quad.level == 0)
        ensures (result.level == 0) {
        if (number_of_live_neighbours == 2) {
            return zero_quad;
        }

        if (number_of_live_neighbours == 3) {
            return QuadFactory.alive;
        }

        return QuadFactory.dead;
    }

    private Quad recursivelly_step_quad_with_speed (Quad quad, int speed) {
        var should_slow_down = speed == quad.level - 2;
        var next_speed = (should_slow_down) ? speed - 1 : speed;

        /*
            nw_ninth   n_ninth   ne_ninth
            w_ninth    c_ninth    e_ninth
            sw_ninth   s_ninth   se_ninth
        */

        var nw_ninth = step_quad_with_speed (quad.nw, next_speed);
        var n_ninth = step_quad_with_speed (tree.north (quad), next_speed);
        var ne_ninth = step_quad_with_speed (quad.ne, next_speed);
        var w_ninth = step_quad_with_speed (tree.west (quad), next_speed);
        var c_ninth = step_quad_with_speed (tree.center (quad), next_speed);
        var e_ninth = step_quad_with_speed (tree.east (quad), next_speed);
        var sw_ninth = step_quad_with_speed (quad.sw, next_speed);
        var s_ninth = step_quad_with_speed (tree.south (quad), next_speed);
        var se_ninth = step_quad_with_speed (quad.se, next_speed);

        var next_nw = factory.create_quad (nw_ninth, n_ninth, c_ninth, w_ninth);
        var next_ne = factory.create_quad (n_ninth, ne_ninth, e_ninth, c_ninth);
        var next_se = factory.create_quad (c_ninth, e_ninth, se_ninth, s_ninth);
        var next_sw = factory.create_quad (w_ninth, c_ninth, s_ninth, sw_ninth);

        if (should_slow_down) {
            return factory.create_quad (
                step_quad_with_speed (next_nw, next_speed),
                step_quad_with_speed (next_ne, next_speed),
                step_quad_with_speed (next_se, next_speed),
                step_quad_with_speed (next_sw, next_speed)
            );
        } else {
            return factory.create_quad (
                tree.center (next_nw),
                tree.center (next_ne),
                tree.center (next_se),
                tree.center (next_sw)
            );
        }
    }

    private void grow_tree_if_necessery (int speed)
        ensures (tree.level >= speed + 2) {
        if (!tree.has_empty_edges ()) {
            tree.grow ();
            tree.grow ();
        } else if (!tree.center_has_empty_edges ()) {
            tree.grow ();
        }

        while (tree.level < speed + 2) {
            tree.grow ();
        }
    }

    public Stats.Metric[] stats () {
        return {
            step_timer,
            steps_cache.elements_counter,
            steps_cache.evict_counter,
            factory.quads_cache.elements_counter,
            factory.quads_cache.evict_counter,
            factory.empty_quads_cache.elements_counter,
            factory.empty_quads_cache.evict_counter
        };
    }
}
