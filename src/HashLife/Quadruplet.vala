/*
* Copyright 2022 Josip Antoliš. (https://josipantolis.from.hr)
* Copyright 2022 Josip Antoliš. (https://josipantolis.from.hr)
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

public class Life.HashLife.Quaduplet<T> : Object {

    public unowned T first { get; construct; }
    public unowned T second { get; construct; }
    public unowned T third { get; construct; }
    public unowned T fourth { get; construct; }

    public Quaduplet (T first, T second, T third, T fourth) {
        Object (
            first: first,
            second: second,
            third: third,
            fourth: fourth
        );
    }

    public uint hash () {
        uint res = 5;
        res = res * 31 + direct_hash (first);
        res = res * 31 + direct_hash (second);
        res = res * 31 + direct_hash (third);
        res = res * 31 + direct_hash (fourth);
        return res;
    }

    public bool equals (Quaduplet<T> other) {
        return first == other.first
            && second == other.second
            && third == other.third
            && fourth == other.fourth;
    }
}
