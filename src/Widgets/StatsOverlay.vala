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

public class Life.Widgets.StatsOverlay : Gtk.Revealer, Stats.MetricVisitor {

    public State state { get; construct; }

    private int rows_count;
    private Gtk.Grid stats_grid;

    public StatsOverlay (State state) {
        Object (
            state: state,
            can_focus: false,
            halign: Gtk.Align.END,
            valign: Gtk.Align.END,
            reveal_child: state.showing_stats,
            transition_type: Gtk.RevealerTransitionType.SLIDE_LEFT
        );
    }

    construct {
        rows_count = 0;
        stats_grid = new Gtk.Grid () {
            column_spacing = 8,
            row_spacing = 16,
            margin = 16
        };
        child = stats_grid;
        state.notify["showing-stats"].connect (() => {
            reveal_child = state.showing_stats;
        });
        state.simulation_updated.connect (() => {
            update_stats_grid ();
        });

        update_stats_grid ();
        ensure_pass_through ();
    }

    private void ensure_pass_through () {
        stats_grid.realize.connect (() => {
            var window = stats_grid.get_window ();
            window.set_pass_through (true);
        });
        realize.connect (() => {
            var window = this.get_window ();
            window.set_pass_through (true);
        });
    }

    private void update_stats_grid () {
        stats_grid.foreach (stats_grid.remove);
        stats_grid.attach (title (), 0, 0);
        rows_count++;
        var stats = state.stats ();
        foreach (var metric in stats) {
            metric.accept (this);
        }
        stats_grid.show_all ();
    }

    private Gtk.Label title () {
        var title = new Gtk.Label (_("Statistics"));
        title.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
        return title;
    }

    public void visit_counter (Stats.Counter counter) {
        var name = new Gtk.Label (counter.name) {
            halign = Gtk.Align.END,
            justify = Gtk.Justification.RIGHT
        };
        stats_grid.attach (name, 0, rows_count);

        var val = new Gtk.Label (("%" + int64.FORMAT).printf (counter.count)) {
            halign = Gtk.Align.START,
            justify = Gtk.Justification.LEFT
        };
        stats_grid.attach (val, 1, rows_count, 2);

        rows_count++;
    }

    public void visit_gauge (Stats.Gauge gauge) {
        var name = new Gtk.Label (gauge.name) {
            halign = Gtk.Align.END,
            justify = Gtk.Justification.RIGHT
        };
        stats_grid.attach (name, 0, rows_count);

        var val = new Gtk.Label ("%f".printf (gauge.val)) {
            halign = Gtk.Align.START,
            justify = Gtk.Justification.LEFT
        };
        stats_grid.attach (val, 1, rows_count, 2);

        rows_count++;
    }

    public void visit_timer (Stats.Timer timer) {
        var name = new Gtk.Label (timer.name) {
            halign = Gtk.Align.END,
            justify = Gtk.Justification.RIGHT
        };
        stats_grid.attach (name, 0, rows_count);

        var format = "Median %.2f ms\n"
            + "75th percentile %.2f ms\n"
            + "99th percentile %.2f ms";
        var txt = format.printf (
            timer.median / 1000,
            timer.percentile_75 / 1000,
            timer.percentile_99 / 1000
        );
        var val = new Gtk.Label (txt) {
            halign = Gtk.Align.START,
            justify = Gtk.Justification.LEFT
        };
        stats_grid.attach (val, 1, rows_count, 2);

        rows_count++;
    }
}
