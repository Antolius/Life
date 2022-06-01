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

public class Life.Shape : Object, Drawable {

    protected int64 _width_points = 0;
    public override int64 width_points { get { return _width_points; } }

    protected int64 _height_points = 0;
    public override int64 height_points { get { return _height_points; } }

    protected Gee.List<Gee.List<bool>> data =
        new Gee.LinkedList<Gee.LinkedList<bool>> ();

    // !Stream
    // .O
    // ..O
    // OOO

    // data: [
    //    0: [0: false, 1: true,  2: false],
    //    1: [0: false, 1: false, 2: true ],
    //    2: [0: true,  1: true,  2: true ],
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
                var point = new Point (
                    i - (width_points / 2),
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

    public void write_into_centered (Editable editable) {
        write_into (editable, new Point (0, 0));
    }

    public void write_into (
        Editable editable,
        Point center,
        bool override_with_dead_cells = true
    ) {
        for (int j = 0; j < height_points; j++) {
            for (int i = 0; i < width_points; i++) {
                var point = new Point (
                    i - (width_points / 2) + center.x,
                    (height_points / 2) - j - 1 + center.y
                );
                var row = data[j];
                var is_alive = row[i];
                if (is_alive || override_with_dead_cells) {
                    editable.set_alive (point, is_alive);
                }
            }
        }
    }

    public bool contains (Point point) {
        return point.x < _width_points
            && point.y < _height_points
            && data[(int) point.y][(int) point.x];
    }

    public void flip_horizontally () {
        foreach (var row in data) {
            for (int i = 0; i < row.size / 2; i++) {
                var tmp = row[i];
                row[i] = row[row.size - i - 1];
                row[row.size - i - 1] = tmp;
            }
        }
    }

    public void flip_vertically () {
        for (int i = 0; i < data.size / 2; i++) {
            var tmp = data[i];
            data[i] = data[data.size - i - 1];
            data[data.size - i - 1] = tmp;
        }
    }

    public void rotate_clockwise () {
        var new_data = new Gee.LinkedList<Gee.LinkedList<bool>> ();
        for (int i = 0; i < width_points; i++) {
            var new_row = new Gee.LinkedList<bool> ();
            for (int j = (int) height_points - 1; j >= 0; j--) {
                new_row.add (data[j][i]);
            }
            new_data.add (new_row);
        }
        data = new_data;
        _width_points = height_points;
        _height_points = data.size;
    }

    public void rotate_counter_clockwise () {
        var new_data = new Gee.LinkedList<Gee.LinkedList<bool>> ();
        for (int i = (int) width_points - 1; i >= 0; i--) {
            var new_row = new Gee.LinkedList<bool> ();
            for (int j = 0; j < height_points; j++) {
                new_row.add (data[j][i]);
            }
            new_data.add (new_row);
        }
        data = new_data;
        _width_points = height_points;
        _height_points = data.size;
    }

    public Stats.Metric[] stats () {
        return {};
    }

    public bool trim_outer_dead_cells () {
        var has_empty_outline = _height_points > 2 && _width_points > 2;

        for (var i = 0; i < height_points && has_empty_outline; i++) {
            has_empty_outline = has_empty_outline
                && !data[i][0] && !data[i][(int) width_points - 1];
        }
        for (var j = 0; j < height_points && has_empty_outline; j++) {
            has_empty_outline = has_empty_outline
                && !data[0][j] && !data[(int) height_points - 1][j];
        }

        if (!has_empty_outline) {
            return false;
        }

        data = data.slice (1, data.size - 1);
        for (var i = 0; i < data.size; i++) {
            data[i] = data[i].slice (1, data[i].size - 1);
        }
        _width_points-=2;
        _height_points-=2;
        return true;
    }

    public string to_string () {
        var res = "";
        foreach (var row in data) {
            var res_row = "";
            foreach (var alive in row) {
                res_row += alive ? "O" : ".";
            }
            res += res_row + "\n";
        }
        return res;
    }
}
