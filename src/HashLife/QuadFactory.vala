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

    public static Quad dead = new Quad.zero_level ();
    public static Quad alive = new Quad.zero_level ();

    public Gee.HashMap<uint32, Quad> empty_quads_cache { get; set; }
    public Gee.HashMap<Quaduplet<Quad>, Quad> quads_cache { get; set; }

    public QuadFactory () {
        Object (
            empty_quads_cache: new Gee.HashMap<uint32, Quad> (),
            quads_cache: new_quads_cache ()
        );
    }

    public Quad create_quad (Quad nw, Quad ne, Quad se, Quad sw) {
        var key = new Quaduplet<Quad> (nw, ne, se, sw);
        var hit = quads_cache[key];
        if (hit == null) {
            hit = new Quad (nw, ne, se, sw);
            quads_cache[key] = hit;
        }

        return hit;
    }

    public void clear_quads_cache (
        Gee.HashMap<Quaduplet<Quad>, Quad> replacement
    ) {
        quads_cache = replacement ?? new_quads_cache ();
    }

    public Quad create_empty_quad (uint32 level) {
        var hit = empty_quads_cache[level];
        if (hit == null) {
            hit = _create_empty_quad (level);
            empty_quads_cache[level] = hit;
        }

        return hit;
    }

    private Quad _create_empty_quad (uint32 level) {
        if (level == 0) {
            return dead;
        }

        var sub = create_empty_quad (level - 1);
        return create_quad (sub, sub, sub, sub);
    }

    public void clear_empty_quads_cache (Gee.HashMap<uint32, Quad> replacement) {
        empty_quads_cache = replacement ?? new Gee.HashMap<uint32, Quad> ();
    }

    private static new Gee.HashMap<Quaduplet<Quad>, Quad> new_quads_cache () {
        return new Gee.HashMap<Quaduplet<Quad>, Quad> (
            q => q.hash (),
            (q1, q2) => q1.equals (q2)
        );
    }
}
