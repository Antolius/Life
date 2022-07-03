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

public class Life.GSettingsManager : Object {

    public Settings settings { get; construct; }
    private ThreadPool<KeyVal>? worker;

    public GSettingsManager (Settings settings) {
        Object (settings: settings);
        try {
            worker = new ThreadPool<KeyVal>.with_owned_data (store, 1, true);
        } catch (ThreadError err) {
            warning ("Failed to create thread pool, will fall back to " +
            "blocking calls to settings. Error: %s", err.message);
            worker = null;
        }
    }

    public bool track_bool (Object source, string key) {
        bool current_val;
        settings.get (key, "b", out current_val);

        source.notify[key].connect ((s, p) => {
            bool new_val;
            s.get (key, out new_val);
            enqueue (new KeyVal.from_boolean (key, new_val));
        });

        return current_val;
    }

    public int track_integer (Object source, string key) {
        int current_val;
        settings.get (key, "i", out current_val);

        source.notify[key].connect ((s, p) => {
            int new_val;
            s.get (key, out new_val);
            enqueue (new KeyVal.from_integer (key, new_val));
        });

        return current_val;
    }

    public string track_string (Object source, string key) {
        string current_val;
        settings.get (key, "s", out current_val);

        source.notify[key].connect ((s, p) => {
            string new_val;
            s.get (key, out new_val);
            enqueue (new KeyVal.from_string (key, new_val));
        });

        return current_val;
    }

    private void enqueue (KeyVal kv) {
        if (worker != null) {
            try {
                worker.add (kv);
                return;
            } catch (ThreadError err) {
                warning ("Failed to enqueue change to %s, will fall back to " +
                "blocking call to settings. Error: %s", kv.key, err.message);
            }
        }

        store (kv);
    }

    private void store (owned KeyVal kv) {
        if (kv.variant != null) {
            settings.set_value (kv.key, kv.variant);
        }

        if (kv.integer != null) {
            settings.set_int (kv.key, kv.integer);
        }

        if (kv.boolean != null) {
            settings.set_boolean (kv.key, kv.boolean);
        }

        if (kv.str != null) {
            settings.set_string (kv.key, kv.str);
        }
    }
}

private class Life.KeyVal : Object {
    public string key;
    public Variant? variant;
    public int? integer;
    public bool? boolean;
    public string? str;

    public KeyVal.from_vaiant (string key, Variant variant) {
        this.key = key;
        this.variant = variant;
        this.integer = null;
        this.boolean = null;
        this.str = null;
    }

    public KeyVal.from_integer (string key, int integer) {
        this.key = key;
        this.variant = null;
        this.integer = integer;
        this.boolean = null;
        this.str = null;
    }

    public KeyVal.from_boolean (string key, bool boolean) {
        this.key = key;
        this.variant = null;
        this.integer = null;
        this.boolean = boolean;
        this.str = null;
    }

    public KeyVal.from_string (string key, string str) {
        this.key = key;
        this.variant = null;
        this.integer = null;
        this.boolean = null;
        this.str = str;
    }
}
