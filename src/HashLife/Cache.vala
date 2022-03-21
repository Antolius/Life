/*
* Copyright 2022 Josip Antoliš. (https://josipantolis.from.hr)
* Copyright 2022 Josip Antoliš. (https://josipantolis.from.hr)
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

public class Life.HashLife.Cache<K> : Object {

    public string name { get; set; }
    public int max_size { get; set; }
    public Stats.Counter hits_counter { get; set; }
    public Stats.Counter miss_counter  { get; set; }
    public Stats.Gauge elements_count { get; set; }

    private ValueProvider<K> _val_provider_func;
    private Gee.HashMap<K, Quad> _cache;
    private Gee.Deque<K> _key_access_order;

    private ThreadPool<CleanupJob<K>>? _cleanup_worker;
    private bool _downsize_scheduled;

    public Cache (
        string name,
        int max_size,
        owned ValueProvider<K> val_provider_func,
        owned Gee.HashDataFunc<K>? key_hash_func = null,
        owned Gee.EqualDataFunc<K>? key_equal_func = null
    ) {
        this.name = name;
        this.max_size = max_size;

        hits_counter = new Stats.Counter () {
            name = name + " hits count",
            description = "Number of times the requested value was found in the cache."
        };

        miss_counter = new Stats.Counter () {
            name = name + " miss count",
            description = "Number of times the requested value was not found in the cache."
        };

        elements_count = new Stats.Gauge () {
            name = name + " elements count",
            description = "Number of elements currently stored in the cache."
        };

        _val_provider_func = (owned) val_provider_func;
        _cache = new Gee.HashMap<K, Quad> (
            k => key_hash_func (k),
            (k1, k2) => key_equal_func (k1, k2)
        );
        _key_access_order = new Gee.LinkedList<K> (
            (k1, k2) => key_equal_func (k1, k2)
        );


        try {
            _cleanup_worker = new ThreadPool<CleanupJob<K>>.with_owned_data (
                job => cleanup (job),
                1,
                true
            );
        } catch (ThreadError err) {
            warning ("Failed to create cleanup thread pool, will proceed " +
            "with degraded performance. Error: %s", err.message);
            _cleanup_worker = null;
        }
        _downsize_scheduled = false;
    }

    public Quad retrieve(K key) {
        var hit = _cache[key];
        if (hit == null) {
            hit = _val_provider_func (key);
            _cache[key] = hit;
            miss_counter.inc ();
            elements_count.inc ();
        } else {
            _hits_counter.inc ();
        }

        if (_cleanup_worker != null) {
            try {
                _cleanup_worker.add (new CleanupJob<K> (key, null));
                return hit;
            } catch (ThreadError err) {
                warning (
                    "Failed to schedule cleanup because of error: %s",
                    err.message
                );
                // Fall through to sync fallback
            }
        }

        update_key_access (key); // synchronous fallback
        return hit;
    }

    private void cleanup (CleanupJob<K> job) {
        if (job.downsize_amount != null) {
            downsize (job.downsize_amount);
        } else if (job.key_to_update != null) {
            update_key_access (job.key_to_update);
        }
    }

    private void update_key_access (K key) {
        _key_access_order.remove (key);
        _key_access_order.offer (key);
        if (!_downsize_scheduled && _cache.size > max_size) {
            _downsize_scheduled = true;
            var amount = (_cache.size - max_size) + (max_size / 10);
            if (_cleanup_worker != null) {
                try {
                    _cleanup_worker.add (new CleanupJob<K> (null, amount));
                    return;
                } catch (ThreadError err) {
                    warning (
                        "Failed to schedule cleanup because of error: %s",
                        err.message
                    );
                    // Fall through to sync fallback
                }
            }

            downsize (amount); // synchronous fallback
        }
    }

    private void downsize (int amount) {
        warning ("Downsizing queue %s by %d", name, amount);
        for (int i = 0; i < amount; i++) {
            var key = _key_access_order.poll_head ();
            if (key != null && _cache.unset (key)) {
                elements_count.dec ();
            }
        }
        _downsize_scheduled = false;
    }
}

public delegate Quad Life.HashLife.ValueProvider<K> (K key);

private class Life.HashLife.CleanupJob<K> : Object {
    public K? key_to_update;
    public int? downsize_amount;

    public CleanupJob (K? key_to_update, int? downsize_amount) {
        this.key_to_update = key_to_update;
        this.downsize_amount = downsize_amount;
    }
}
