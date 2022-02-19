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

public class Life.Point : Object {

    public int64 x { get; construct; }
    public int64 y { get; construct; }

    public Point (int64 x, int64 y) {
        Object (x: x, y: y);
    }

    public Point x_add (int64 x_delta) {
        return new Point (x + x_delta, y);
    }

    public Point y_add (int64 y_delta) {
        return new Point (x, y + y_delta);
    }

    public Point add (int64 delta) {
        return new Point (x + delta, y + delta);
    }

    public Point flip_h () {
        return new Point (x, -y);
    }

    public Point flip_v () {
        return new Point (-x, y);
    }

    public Point flip () {
        return new Point (-x, -y);
    }

    public Point scale (int64 factor) {
        return new Point (x * factor, y * factor);
    }

    public Point scale_imprecise (double factor) {
        return new Point (
            (int64) Math.floor (x * factor),
            (int64) Math.floor (y * factor)
        );
    }

    public string to_string () {
        return ("(%" + int64.FORMAT + ", %" + int64.FORMAT + ")").printf (x, y);
    }

}
