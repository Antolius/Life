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

public class Life.CutoutShape : Shape {

    public CutoutShape.entire (Drawable drawable) {
        bool is_zeroed_out = false;

        drawable.draw_optimal ((point_in_dravable, max_width, max_height) => {
            if (!is_zeroed_out) {
                _width_points = max_width;
                _height_points = max_height;
                zero_out_cells ();
                is_zeroed_out = true;
            }

            var relative_point_in_cutout = new Point (
                point_in_dravable.x + (width_points / 2),
                point_in_dravable.y + (height_points / 2)
            );

            var i = relative_point_in_cutout.x;
            var j = height_points - relative_point_in_cutout.y - 1;

            data[(int) j][(int) i] = true;
        });

        if (!is_zeroed_out) {
            _width_points = 1;
            _height_points = 1;
            zero_out_cells ();
            zero_out_cells ();
        }
    }

    public CutoutShape (Rectangle boundary, Drawable larger_drawable) {
        _width_points = boundary.width;
        _height_points = boundary.height;
        zero_out_cells ();

        larger_drawable.draw (boundary, (point_in_larger_drawable) => {
            var relative_point_in_cutout = new Point (
                point_in_larger_drawable.x - boundary.bottom_left.x,
                point_in_larger_drawable.y - boundary.bottom_left.y
            );

            var i = relative_point_in_cutout.x;
            var j = height_points - relative_point_in_cutout.y - 1;

            data[(int) j][(int) i] = true;
        });
    }

    private void zero_out_cells () {
        for (var j = 0; j < height_points; j++) {
            var row = new Gee.LinkedList<bool> ();
            for (var i = 0; i < width_points; i++) {
                row.add (false);
            }
            data.add (row);
        }
    }
}
