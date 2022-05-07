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

public class Life.HashLife.Pair<T, S> : Object {

    public unowned T first { get; construct; }
    public unowned S second { get; construct; }

    public Pair (T first, S second) {
        Object (
            first: first,
            second: second
        );
    }

    public uint hash () {
        uint res = 5;
        res = res * 31 + direct_hash (first);
        res = res * 31 + direct_hash (second);
        return res;
    }

    public bool equals (Pair<T, S> other) {
        return first == other.first
            && second == other.second;
    }
}
