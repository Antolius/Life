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

public class Life.Stats.Gauge : Metric {

    public double val { get; private set; default = 0; }

    private Mutex mutex = Mutex ();

    public override void accept (MetricVisitor visitor) {
        visitor.visit_gauge (this);
    }

    public void inc (double dif = 1) {
        mutex.lock ();
        val += dif;
        mutex.unlock ();
    }

    public void dec (double dif = 1) {
        mutex.lock ();
        val -= dif;
        mutex.unlock ();
    }

    public void assign (double new_val) {
        mutex.lock ();
        val = new_val;
        mutex.unlock ();
    }
}
