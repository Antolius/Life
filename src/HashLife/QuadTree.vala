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

public class Life.HashLife.QuadTree : Object, Drawable {

    public const uint32 MAX_LEVEL = 60;

    public unowned Quad root { get; set; }
    public QuadFactory factory { get; construct; }
    public int64 width_points { get { return root.width; } }
    public int64 height_points { get { return root.width; } }

    public QuadTree (int level = 1, QuadFactory factory = new QuadFactory ()) {
        Object (
            factory: factory,
            root: factory.create_empty_quad (level)
        );
    }

    // Coordinates for level 2 QuadTree:
    //
    // (-2,  1) | (-1,  1) || (0,  1) | (1,  1)
    // --------------------||------------------
    // (-2,  0) | (-1,  0) || (0,  0) | (1,  0)
    // ========================================
    // (-2, -1) | (-1, -1) || (0, -1) | (1, -1)
    // --------------------||------------------
    // (-2, -2) | (-1, -2) || (0, -2) | (1, -2)

    public bool is_alive (Point p) {
        return _is_alive (root, bottom_left (), p);
    }

    private bool _is_alive (Quad q, Point bottom_left, Point p) {
        if (!q.rect (bottom_left).contains (p)) {
            return false;
        }

        if (q.level == 0) {
            return q == QuadFactory.alive;
        }

        var w = q.width / 2;
        if (p.x >= bottom_left.x + w) {
            if (p.y >= bottom_left.y + w) {
                return _is_alive (q.ne, bottom_left.add (w), p);
            } else {
                return _is_alive (q.nw, bottom_left.x_add (w), p);
            }
        } else if (p.y >= bottom_left.y + w) {
            return _is_alive (q.nw, bottom_left.y_add (w), p);
        } else {
            return _is_alive (q.sw, bottom_left, p);
        }
    }

    public void set_alive (Point p, bool alive) {
        root = _set_alive (root, bottom_left (), p, alive);
    }

    private Quad _set_alive (Quad q, Point bottom_left, Point p, bool alive) {
        if (!q.rect (bottom_left).contains (p)) {
            return q;
        }

        if (q.level == 0) {
            return alive ? QuadFactory.alive : QuadFactory.dead;
        }

        var w = q.width / 2;
        return factory.create_quad (
            _set_alive (q.nw, bottom_left.y_add (w), p, alive),
            _set_alive (q.ne, bottom_left.add (w), p, alive),
            _set_alive (q.se, bottom_left.x_add (w), p, alive),
            _set_alive (q.sw, bottom_left, p, alive)
        );
    }

    public bool contains (Point p) {
        return root.rect (bottom_left ()).contains (p);
    }

    public void draw_entire (DrawAction draw_action) {
        draw (draw_action, root.rect (bottom_left ()));
    }

    public void draw (DrawAction draw_action, Rectangle drawing_area) {
        _draw (root, bottom_left (), draw_action, drawing_area);
    }

    public void _draw (
        Quad q,
        Point bottom_left,
        DrawAction draw_action,
        Rectangle drawing_area
    ) {
        if (is_empty (q)) {
            return;
        }

        if (!q.rect (bottom_left).overlaps (drawing_area)) {
            return;
        }

        if (q.level == 0 && q == QuadFactory.alive) {
            draw_action (bottom_left);
            return;
        }

        var w = q.width / 2;
        _draw (q.nw, bottom_left.y_add (w), draw_action, drawing_area);
        _draw (q.ne, bottom_left.add (w), draw_action, drawing_area);
        _draw (q.se, bottom_left.x_add (w), draw_action, drawing_area);
        _draw (q.sw, bottom_left, draw_action, drawing_area);
    }

    private void _advance (int num_of_steps) {

    }

    private bool is_empty (Quad q) {
        return q == factory.create_empty_quad (q.level);
    }

    private Point bottom_left () {
        return new Point (-root.width / 2, -root.width / 2);
    }

    private Quad center (Quad q) {
        assert (q.level >= 2);
        return factory.create_quad (q.nw.se, q.ne.sw, q.se.nw, q.sw.ne);
    }

    private Quad north (Quad q) {
        assert (q.level >= 2);
        return factory.create_quad (q.nw.ne, q.ne.nw, q.ne.sw, q.nw.se);
    }

    private Quad east (Quad q) {
        assert (q.level >= 2);
        return factory.create_quad (q.ne.sw, q.ne.se, q.se.ne, q.se.nw);
    }

    private Quad south (Quad q) {
        assert (q.level >= 2);
        return factory.create_quad (q.sw.ne, q.se.nw, q.se.sw, q.sw.se);
    }

    private Quad weast (Quad q) {
        assert (q.level >= 2);
        return factory.create_quad (q.nw.sw, q.nw.se, q.sw.nw, q.sw.nw);
    }

    private bool has_empty_edges (Quad q) {
        return q.level >= 2
            && is_empty (q.nw.nw) && is_empty (q.nw.ne) && is_empty (q.nw.sw)
            && is_empty (q.ne.nw) && is_empty (q.ne.ne) && is_empty (q.ne.se)
            && is_empty (q.se.ne) && is_empty (q.se.se) && is_empty (q.se.sw)
            && is_empty (q.sw.nw) && is_empty (q.sw.se) && is_empty (q.sw.sw);
    }

    private void grow () {
        if (root.level >= MAX_LEVEL) {
            return;
        }

        var border = factory.create_empty_quad (root.level - 1);
        root = factory.create_quad (
            factory.create_quad (border, border, root.nw, border),
            factory.create_quad (border, border, border, root.ne),
            factory.create_quad (root.se, border, border, border),
            factory.create_quad (border, root.sw, border, border)
        );
    }
}