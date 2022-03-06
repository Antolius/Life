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

public class Life.Stats.Timer : Metric {

    private double[] _dataset = {};
    private size_t _dataset_size = 0;

    public double min {
        get {
            lock (_dataset) {
                return _dataset_size > 0 ? _dataset[0] : double.MIN;
            }
        }
    }

    public double max {
        get {
            lock (_dataset) {
                return _dataset_size > 0 ? _dataset[_dataset_size - 1] : double.MAX;
            }
        }
    }

    public double median {
        get {
            lock (_dataset) {
                return Gsl.Stats.median_from_sorted_data (_dataset, 1, _dataset_size);
            }
        }
    }

    public double percentile_75 {
        get {
            lock (_dataset) {
                return Gsl.Stats.quantile_from_sorted_data (_dataset, 1, _dataset_size, 0.75);
            }
        }
    }

    public double percentile_90 {
        get {
            lock (_dataset) {
                return Gsl.Stats.quantile_from_sorted_data (_dataset, 1, _dataset_size, 0.90);
            }
        }
    }

    public double percentile_95 {
        get {
            lock (_dataset) {
                return Gsl.Stats.quantile_from_sorted_data (_dataset, 1, _dataset_size, 0.95);
            }
        }
    }

    public double percentile_99 {
        get {
            lock (_dataset) {
                return Gsl.Stats.quantile_from_sorted_data (_dataset, 1, _dataset_size, 0.99);
            }
        }
    }

    public override void accept (MetricVisitor visitor) {
        visitor.visit_timer (this);
    }

    public StopTimerAction start_timer () {
        var start_time = (double) get_monotonic_time ();
        return () => {
            var stop_time = (double) get_monotonic_time ();
            var spent_time = stop_time - start_time;
            lock (_dataset) {
                _dataset += spent_time;
                _dataset_size++;
                Gsl.Sort.sort (_dataset, 1, _dataset_size);
            }
        };
    }
}

public delegate void Life.Stats.StopTimerAction ();
