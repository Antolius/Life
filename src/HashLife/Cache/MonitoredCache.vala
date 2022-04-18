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

public class Life.HashLife.Cache.MonitoredCache<K, V> : LoadingCache<K, V> {

    public string name { get; construct; }
    public Stats.Counter access_counter { get; construct; }
    public Stats.Counter load_counter { get; construct; }
    public Stats.Counter evict_counter { get; construct; }
    public Stats.Gauge elements_counter { get; construct; }

    private LoadingCache<K, V> base_cache;

    public MonitoredCache (
        string name,
        LoadingCache<K, V> base_cache
    ) {
        Object (
            name: name,
            access_counter: new Stats.Counter () {
                name = _("%s access counter").printf (name),
                description = _("Number of times value was accessed from the cache.")
            },
            load_counter: new Stats.Counter () {
                name = _("%s load count").printf (name),
                description = _("Number of times value was loaded into the cache.")
            },
            evict_counter: new Stats.Counter () {
                name = _("%s evict count").printf (name),
                description = _("Number of times value was evicted from the cache.")
            },
            elements_counter: new Stats.Gauge () {
                name = _("%s elements count").printf (name),
                description = _("Number of elements currently stored in the cache.")
            }
        );

        this.base_cache = base_cache;
        connect_signals ();
    }

    public override V? access (K key) {
        access_counter.inc ();
        return base_cache.access (key);
    }

    private void connect_signals () {
        base_cache.loaded.connect ((key, val) => {
            load_counter.inc ();
            loaded (key, val);
        });

        base_cache.evicted.connect ((key, val) => {
            evict_counter.inc ();
            evicted (key, val);
        });

        base_cache.notify ["size"].connect (() => {
            elements_counter.assign ((double) base_cache.size);
        });
    }

}
