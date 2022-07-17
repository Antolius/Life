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

public class Life.HashLife.Pair : Object {

    public unowned Quad first { get; construct; }
    public unowned int second { get; construct; }
    public uint hash { get {
        uint res = 7;
        res = res * 31 + first.hash;
        res = res * 31 + (uint) second;
        return res;
    } }

    public Pair (Quad first, int second) {
        Object (
            first: first,
            second: second
        );
    }

    public bool equals (Pair other) {
        if (this == other) {
            return true;
        }

        if (other == null) {
            return false;
        }

        return (first == null && other .first == null
            || first.equals (other.first))
            && second == other.second;
    }
}
