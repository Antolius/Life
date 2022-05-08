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

public class Life.Pattern : Object {

    public string name { get; set; default = "unnamed pattern"; }
    public string? author { get; set; }
    public string? description { get; set; }
    public string? link { get; set; }
    public int width { get; set; default = 0; }
    public int height { get; set; default = 0; }
    public Gee.List<Gee.List<bool>> data {
        get;
        set;
        default = new Gee.LinkedList<Gee.LinkedList<bool>> ();
    }

    public static async Pattern from_plaintext (InputStream stream) {
        var pattern = new Pattern ();

        var ds = new DataInputStream (stream);
        string? line = null;

        while (true) {
            line = yield ds.read_line_async ();
            if (line == null) {
                break;
            }

            if (line.has_prefix ("!")) {
                if (line.has_prefix ("!Name: ")) {
                    pattern.name = line.substring ("!Name: ".length);
                } else if (line.has_prefix ("!Author: ")) {
                    pattern.author = line.substring ("!Author: ".length);
                } else if (line.has_prefix ("!Description: ")) {
                    pattern.description = line.substring ("!Description: ".length);
                } else if (line.has_prefix ("!Link: ")) {
                    pattern.link = line.substring ("!Link: ".length);
                }
            } else {
                pattern.height++;
                if (line.length > pattern.width) {
                    pattern.width = line.length;
                }

                var row = new Gee.LinkedList<bool> ();
                unichar c;
                for (int i = 0; line.get_next_char (ref i, out c);) {
                    row.add (c == 'O');
                }
                pattern.data.add (row);
            }
        }

        return pattern;
    }

}
