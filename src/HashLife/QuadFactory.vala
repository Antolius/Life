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

public class Life.HashLife.QuadFactory : Object {

    public static Quad dead = new Quad.zero_level (0);
    public static Quad alive = new Quad.zero_level (1);

    public Cache.MonitoredCache<uint32, Quad> empty_quads_cache { get; set; }
    public Cache.MonitoredCache<Quaduplet, Quad> quads_cache { get; set; }

    construct {
        empty_quads_cache = new Cache.MonitoredCache<uint32, Quad> (
            "Empty quads cacne",
            new Cache.LfuCache<uint32, Quad> (
                100,
                _create_empty_quad,
                i => (uint) i,
                (i1, i2) => i1 == i2,
                (q1, q2) => q1 == null && q2 == null || q1.equals (q2)
            )
        );

        quads_cache = new Cache.MonitoredCache<Quaduplet, Quad> (
            "Quads cacne",
            new Cache.LfuCache<Quaduplet, Quad> (
                // 1000, // < 20 MiB,
                // 10000, // < 30 MiB,
                100000, // < 100 MiB
                // 1000000, // < 800 MiB
                _create_quad,
                q => q.hash,
                (q1, q2) => q1 == null && q2 == null || q1.equals (q2),
                (q1, q2) => q1 == null && q2 == null || q1.equals (q2)
            )
        );
    }

    public Quad create_quad (Quad nw, Quad ne, Quad se, Quad sw)
        requires (nw.level == ne.level)
        requires (ne.level == se.level)
        requires (se.level == sw.level)
        ensures (result.level == sw.level + 1) {
        var key = new Quaduplet (nw, ne, se, sw);
        return quads_cache.access (key);
    }

    private Quad _create_quad (Quaduplet q) {
        return new Quad (q.first, q.second, q.third, q.fourth);
    }

    public Quad create_empty_quad (uint32 level) {
        return empty_quads_cache.access (level);
    }

    private Quad _create_empty_quad (uint32 level)
        ensures (result.level == level) {
        if (level == 0) {
            return dead;
        }

        var sub = create_empty_quad (level - 1);
        return create_quad (sub, sub, sub, sub);
    }
}
