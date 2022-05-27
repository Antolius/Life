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

public class Life.Rectangle : Object {

    public Point bottom_left { get; construct; }
    public int64 height { get; construct; }
    public int64 width { get; construct; }

    public Rectangle (Point bottom_left, int64 height, int64 width) {
        Object (
            bottom_left: bottom_left,
            height: height,
            width: width
        );
    }

    public Point top_rigth () {
        return new Point (bottom_left.x + width, bottom_left.y + height);
    }

    public Point top_left () {
        return new Point (bottom_left.x, bottom_left.y + height);
    }

    public bool contains (Point point) {
        return bottom_left.x <= point.x && point.x < bottom_left.x + width
            && bottom_left.y <= point.y && point.y < bottom_left.y + height;
    }

    public bool overlaps (Rectangle other) {
        var other_bottom_left = other.bottom_left;
        var other_top_right = other.top_rigth ();
        var this_bottom_left = bottom_left;
        var this_top_right = top_rigth ();
        return other_bottom_left.x < this_top_right.x
            && other_top_right.x > this_bottom_left.x
            && other_bottom_left.y < this_top_right.y
            && other_top_right.y > this_bottom_left.y;
    }

    public string to_string () {
        return ("[%s/%s]".printf (
            bottom_left.to_string (),
            top_rigth ().to_string ()
        ));
    }
}
