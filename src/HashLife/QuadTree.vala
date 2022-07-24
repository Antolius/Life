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

public class Life.HashLife.QuadTree : Object, Drawable, Editable {

    public const uint32 MAX_LEVEL = 60;

    private Quad _root;
    public Quad root {
        get { return _root; }
        set {
            level_gauge.assign ((double) value.level);
            _root = value;
        }
    }
    public QuadFactory factory { get; construct; }
    public int64 width_points { get { return root.width; } }
    public int64 height_points { get { return root.width; } }
    public uint level { get { return root.level; } }

    private Stats.Timer draw_timer = new Stats.Timer () {
        name = _("Draw timer"),
        description = _("Time spent in QuatTree's draw method.")
    };

    private Stats.Gauge level_gauge = new Stats.Gauge () {
        name = _("Quad tree level"),
        description = _("Level of the quad tree, indicative of its size.")
    };

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

    public bool is_empty () {
        Lock.rw.reader_lock ();
        try {
            return _is_empty (root);
        } finally {
            Lock.rw.reader_unlock ();
        }
    }

    public bool is_alive (Point p) {
        Lock.rw.reader_lock ();
        try {
            return _is_alive (root, bottom_left (), p);
        } finally {
            Lock.rw.reader_unlock ();
        }
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

    public void resize_to_encompass (
        int64 max_width,
        int64 max_height
    )
        ensures (root.width >= max_width)
        ensures (root.width >= max_height) {
        Lock.rw.writer_lock ();
        try {
            var max = int64.max (max_width, max_height);
            while (root.width <= max) {
                grow ();
            }
        } finally {
            Lock.rw.writer_unlock ();
        }
    }

    public void set_alive (Point p, bool alive)
        requires (root.width >= p.x.abs () / 2)
        requires (root.width >= p.y.abs () / 2) {
        Lock.rw.writer_lock ();
        try {
            root = _set_alive (root, bottom_left (), p, alive);
        } finally {
            Lock.rw.writer_unlock ();
        }
    }

    private Quad _set_alive (Quad q, Point bottom_left, Point p, bool alive)
        ensures (result.level == q.level) {
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

    public void clear_all () {
        Lock.rw.writer_lock ();
        try {
            root = factory.create_empty_quad (level);
        } finally {
            Lock.rw.writer_unlock ();
        }
    }

    public bool contains (Point p) {
        return root.rect (bottom_left ()).contains (p);
    }

    public void draw_entire (DrawAction draw_action) {
        Lock.rw.reader_lock ();
        try {
            var stop_timer = draw_timer.start_timer ();
            _draw (root, bottom_left (), root.rect (bottom_left ()), draw_action);
            stop_timer ();
        } finally {
            Lock.rw.reader_unlock ();
        }
    }

    public void draw_optimal (OptimizedDrawAction draw_action) {
        Lock.rw.reader_lock ();
        try {
            var trimmed_root = root;
            while (_has_empty_edges (trimmed_root) && trimmed_root.level > 2) {
                trimmed_root = center (trimmed_root);
            }

            var bl = new Point (
                -trimmed_root.width / 2,
                -trimmed_root.width / 2
            );
            var drawing_area = trimmed_root.rect (bl);
            var stop_timer = draw_timer.start_timer ();
            _draw (
                root,
                bottom_left (),
                drawing_area,
                (p) => {
                    draw_action (p, trimmed_root.width, trimmed_root.width);
                }
            );
            stop_timer ();
        } finally {
            Lock.rw.reader_unlock ();
        }
    }

    public void draw (Rectangle drawing_area, DrawAction draw_action) {
        Lock.rw.reader_lock ();
        try {
            var stop_timer = draw_timer.start_timer ();
            _draw (root, bottom_left (), drawing_area, draw_action);
            stop_timer ();
        } finally {
            Lock.rw.reader_unlock ();
        }
    }

    public void _draw (
        Quad q,
        Point bottom_left,
        Rectangle drawing_area,
        DrawAction draw_action
    ) {
        if (_is_empty (q)) {
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
        _draw (q.nw, bottom_left.y_add (w), drawing_area, draw_action);
        _draw (q.ne, bottom_left.add (w), drawing_area, draw_action);
        _draw (q.se, bottom_left.x_add (w), drawing_area, draw_action);
        _draw (q.sw, bottom_left, drawing_area, draw_action);
    }

    public bool _is_empty (Quad q) {
        return q == factory.create_empty_quad (q.level);
    }

    public Point bottom_left () {
        return new Point (-width_points / 2, -height_points / 2);
    }

    public Quad center (Quad q)
        requires (q.level >= 2)
        ensures (result.level == q.level - 1) {
        return factory.create_quad (q.nw.se, q.ne.sw, q.se.nw, q.sw.ne);
    }

    public Quad north (Quad q)
        requires (q.level >= 2)
        ensures (result.level == q.level - 1) {
        return factory.create_quad (q.nw.ne, q.ne.nw, q.ne.sw, q.nw.se);
    }

    public Quad east (Quad q)
        requires (q.level >= 2)
        ensures (result.level == q.level - 1) {
        return factory.create_quad (q.ne.sw, q.ne.se, q.se.ne, q.se.nw);
    }

    public Quad south (Quad q)
        requires (q.level >= 2)
        ensures (result.level == q.level - 1) {
        return factory.create_quad (q.sw.ne, q.se.nw, q.se.sw, q.sw.se);
    }

    public Quad west (Quad q)
        requires (q.level >= 2)
        ensures (result.level == q.level - 1) {
        return factory.create_quad (q.nw.sw, q.nw.se, q.sw.ne, q.sw.nw);
    }

    public bool has_empty_edges () {
        return _has_empty_edges (root);
    }

    public bool center_has_empty_edges () {
        return _has_empty_edges (center (root));
    }

    private bool _has_empty_edges (Quad q) {
        return q.level >= 2
            && _is_empty (q.nw.nw) && _is_empty (q.nw.ne) && _is_empty (q.nw.sw)
            && _is_empty (q.ne.nw) && _is_empty (q.ne.ne) && _is_empty (q.ne.se)
            && _is_empty (q.se.ne) && _is_empty (q.se.se) && _is_empty (q.se.sw)
            && _is_empty (q.sw.nw) && _is_empty (q.sw.se) && _is_empty (q.sw.sw);
    }

    public void grow ()
        requires (level < MAX_LEVEL) {
        var border = factory.create_empty_quad (level - 1);
        root = factory.create_quad (
            factory.create_quad (border, border, root.nw, border),
            factory.create_quad (border, border, border, root.ne),
            factory.create_quad (root.se, border, border, border),
            factory.create_quad (border, root.sw, border, border)
        );
    }

    public Stats.Metric[] stats () {
        Lock.rw.reader_lock ();
        try {
            return { draw_timer, level_gauge };
        } finally {
            Lock.rw.reader_unlock ();
        }
    }
}
