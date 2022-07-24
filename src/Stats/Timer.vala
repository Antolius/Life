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

    private Mutex mutex = Mutex ();

    public double min {
        get {
            mutex.lock ();
            try {
                return _dataset_size > 0 ? _dataset[0] : 0;
            } finally {
                mutex.unlock ();
            }
        }
    }

    public double max {
        get {
            mutex.lock ();
            try {
                return _dataset_size > 0 ? _dataset[_dataset_size - 1] : 0;
            } finally {
                mutex.unlock ();
            }
        }
    }

    public double median {
        get {
            mutex.lock ();
            try {
                return Gsl.Stats.median_from_sorted_data (_dataset, 1, _dataset_size);
            } finally {
                mutex.unlock ();
            }
        }
    }

    public double percentile_75 {
        get {
            mutex.lock ();
            try {
                return Gsl.Stats.quantile_from_sorted_data (_dataset, 1, _dataset_size, 0.75);
            } finally {
                mutex.unlock ();
            }
        }
    }

    public double percentile_90 {
        get {
            mutex.lock ();
            try {
                return Gsl.Stats.quantile_from_sorted_data (_dataset, 1, _dataset_size, 0.90);
            } finally {
                mutex.unlock ();
            }
        }
    }

    public double percentile_95 {
        get {
            mutex.lock ();
            try {
                return Gsl.Stats.quantile_from_sorted_data (_dataset, 1, _dataset_size, 0.95);
            } finally {
                mutex.unlock ();
            }
        }
    }

    public double percentile_99 {
        get {
            mutex.lock ();
            try {
                return Gsl.Stats.quantile_from_sorted_data (_dataset, 1, _dataset_size, 0.99);
            } finally {
                mutex.unlock ();
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
            mutex.lock ();
            try {
                _dataset += spent_time;
                _dataset_size++;
                Gsl.Sort.sort (_dataset, 1, _dataset_size);
            } finally {
                mutex.unlock ();
            }
        };
    }
}

public delegate void Life.Stats.StopTimerAction ();
