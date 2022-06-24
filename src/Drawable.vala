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

public interface Life.Drawable : Object {

    public abstract int64 width_points { get; }
    public abstract int64 height_points { get; }

    public abstract void draw (Rectangle drawing_area, DrawAction draw_action);
    public abstract void draw_entire (DrawAction draw_action);
    public abstract void draw_optimal (OptimizedDrawAction draw_action);

    public abstract Stats.Metric[] stats ();
}

public delegate void Life.DrawAction (Point p);

public delegate void Life.OptimizedDrawAction (
    Point p,
    int64 optimal_width,
    int64 optimal_height
);
