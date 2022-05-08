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

public class Life.Pattern : Object, Drawable {

    public string name { get; set; default = "unnamed pattern"; }
    public string? author { get; set; }
    public string? description { get; set; }
    public string? link { get; set; }

    private int64 _width_points = 0;
    public override int64 width_points { get { return _width_points; } }

    private int64 _height_points = 0;
    public override int64 height_points { get { return _height_points; } }

    private Gee.List<Gee.List<bool>> data =
        new Gee.LinkedList<Gee.LinkedList<bool>> ();

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
                pattern._height_points++;
                if (line.length > pattern._width_points) {
                    pattern._width_points = line.length;
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

    // !Stream
    // .O
    // ..O
    // OOO

    // data: [
    //    0: [0: false, 1: true],
    //    1: [0: false, 1: false, 2: true],
    //    2: [0: true,  1: true,  2: true],
    // ]
    // width_points: 3
    // height_points: 3

    // Point coordinates:
    //
    // (-1,  0) F | (0,  0) T | (1,  0) F
    // -----------|-----------|----------
    // (-1, -1) F | (0, -1) F | (1, -1) T
    // -----------|-----------|----------
    // (-1, -2) T | (0, -2) T | (1, -2) T

    public void draw (Rectangle drawing_area, DrawAction draw_action) {
        for (int j = 0; j < height_points; j++) {
            for (int i = 0; i < width_points; i++) {
                var point = new Point (i - (width_points / 2),
                    (height_points / 2) - j - 1
                );
                if (drawing_area.contains (point)) {
                    var row = data[j];
                    if (row.size > i && row[i]) {
                        draw_action (point);
                    }
                }
            }
        }
    }

    public void draw_entire (DrawAction draw_action) {
        var bottom_left = new Point (-width_points / 2, -height_points / 2);
        var full_rec = new Rectangle (bottom_left, height_points, width_points);
        draw (full_rec, draw_action);
    }

    public Stats.Metric[] stats () {
        return {};
    }

}
