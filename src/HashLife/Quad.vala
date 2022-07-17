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

public class Life.HashLife.Quad : Object {

    public Quad nw { get; construct; }
    public Quad ne { get; construct; }
    public Quad se { get; construct; }
    public Quad sw { get; construct; }
    public uint hash { get; construct; }
    public uint level { get; construct; }
    public int64 width { get { return 1 << level; }}

    public Quad.zero_level (uint hash) {
        Object (
            nw: this,
            ne: this,
            se: this,
            sw: this,
            hash: hash,
            level: 0
        );
    }

    public Quad (Quad nw, Quad ne, Quad se, Quad sw) {
        Object (
            nw: nw,
            ne: ne,
            se: se,
            sw: sw,
            hash: calculate_hash (nw, ne, se, sw),
            level: nw.level + 1
        );
    }

    public Rectangle rect (Point bottom_left) {
        return new Rectangle (bottom_left, width, width);
    }

    public bool equals (Quad other) {
        if (this == other) {
            return true;
        }

        if (other == null) {
            return false;
        }

        return level == other.level
            && hash == other.hash
            && nw.equals (other.nw)
            && ne.equals (other.ne)
            && se.equals (other.se)
            && sw.equals (other.sw);
    }

    private static uint calculate_hash (Quad nw, Quad ne, Quad se, Quad sw) {
        uint res = 7;
        res = 31 * res + nw.hash;
        res = 31 * res + ne.hash;
        res = 31 * res + se.hash;
        res = 31 * res + sw.hash;
        return res;
    }
}
