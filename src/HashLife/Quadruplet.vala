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

public class Life.HashLife.Quaduplet : Object {

    public unowned Quad first { get; construct; }
    public unowned Quad second { get; construct; }
    public unowned Quad third { get; construct; }
    public unowned Quad fourth { get; construct; }
    public uint hash { get {
        uint res = 7;
        res = res * 31 + first.hash;
        res = res * 31 + second.hash;
        res = res * 31 + third.hash;
        res = res * 31 + fourth.hash;
        return res;
    } }

    public Quaduplet (Quad first, Quad second, Quad third, Quad fourth) {
        Object (
            first: first,
            second: second,
            third: third,
            fourth: fourth
        );
    }

    public bool equals (Quaduplet other) {
        if (this == other) {
            return true;
        }

        if (other == null) {
            return false;
        }

        return (first == null && other.first == null || first.equals (other.first))
            && (second == null && other.second == null || second.equals (other.second))
            && (third == null && other.third == null || third.equals (other.third))
            && (fourth == null && other.fourth == null || fourth.equals (other.fourth));
    }
}
