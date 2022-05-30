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


/* Refferences:
    https://arpitbhayani.me/blogs/lfu
    http://dhruvbird.com/lfu.pdf
*/
public class Life.HashLife.Cache.LfuCache<Key, Value> : LoadingCache<Key, Value> {

    public int max_size { get; construct; }

    private Gee.Map<Key, Node<Key, Value>> key_to_node;
    private Frequency<Key, Value>* freq_head;
    private CacheLoader<Key, Value> cache_loader_func;

    public LfuCache (
        int max_size,
        owned CacheLoader<Key, Value> cache_loader_func,
        owned Gee.HashDataFunc<Key>? key_hash_func = null,
        owned Gee.EqualDataFunc<Key>? key_equal_func = null,
        owned Gee.EqualDataFunc<Value>? value_equal_func = null
    ) {
        Object (max_size : max_size);

        this.cache_loader_func = (owned) cache_loader_func;
        freq_head = null;
        key_to_node = new Gee.HashMap<Key, Node<Key, Value>> (
            (owned) key_hash_func,
            (owned) key_equal_func,
            (n1, n2) => {
                if (n1 == n2) {
                    return true;
                }

                Gee.EqualDataFunc<Key> key_eq;
                if (key_equal_func != null) {
                    key_eq = (k1, k2) => key_equal_func (k1, k2);
                } else {
                    key_eq = Gee.Functions.get_equal_func_for (typeof (Key));
                }

                Gee.EqualDataFunc<Value> val_eq;
                if (value_equal_func != null) {
                    val_eq = (v1, v2) => value_equal_func (v1, v2);
                } else {
                    val_eq = Gee.Functions.get_equal_func_for (typeof (Value));
                }

                return key_eq (n1.key, n2.key) && val_eq (n1.val, n2.val);
            }
        );
    }

    public override Value? access (Key key) {
        lock (key_to_node) {
            var node = key_to_node[key];
            if (node == null) {
                var new_val = cache_loader_func (key);
                loaded (key, new_val);
                if (new_val == null) {
                    warning ("Loader returned null!");
                    return null;
                }

                var new_node = insert (key, new_val);
                return new_node.val;
            }

            // Because node is somewhere in the cache:
            assert (freq_head != null);
            assert (node.parent != null);

            // Create next frequency if needed:
            var old_freq = node.parent;
            var future_freq = old_freq->next;
            if (future_freq == null || future_freq->freq != old_freq->freq + 1) {
                // Create next incremental frequency
                future_freq = new Frequency<Key, Value> (old_freq->freq + 1);
                future_freq->prev = old_freq;
                future_freq->next = old_freq->next;
                if (old_freq->next != null) {
                    old_freq->next->prev = future_freq;
                }
                old_freq->next = future_freq;
            }

            // Move node into next frequency:
            old_freq->remove_node (node);
            future_freq->add_node (node);

            if (old_freq->is_empty) {
                if (freq_head == old_freq) {
                    // Because we never remove all elements:
                    assert (freq_head->next != null);
                    freq_head = freq_head->next;
                }

                old_freq->remove_self ();
                delete old_freq;
            }

            return node.val;
        }
    }

    private Node<Key, Value> insert (Key key, Value val)
        requires (!key_to_node.has_key (key))
        ensures (result.parent != null)
        ensures (result.parent->freq == 1)
        ensures (result == key_to_node[key])
        ensures (freq_head != null)
        ensures (freq_head->prev == null)
        ensures (freq_head->node_head != null)
        ensures (size <= max_size) {
        if (size >= max_size) {
            var target_size = max_size * 0.6;
            do {
                evict ();
            } while (size > target_size);
        }

        // Ensure freq_head has frequency 1:
        if (freq_head == null) {
            freq_head = new Frequency<Key, Value> ();
        } else if (freq_head->freq != 1) {
            Frequency<Key, Value>* new_freq = new Frequency<Key, Value> ();
            new_freq->next = freq_head;
            freq_head->prev = new_freq;
            freq_head = new_freq;
        }
        assert (freq_head->freq == 1);

        var node = new Node<Key, Value> (key, val);
        freq_head->add_node (node);
        key_to_node[key] = node;
        size++;
        return node;
    }

    private void evict ()
        requires (freq_head != null)
        requires (freq_head->node_head != null)
        ensures (size < max_size)
        ensures (freq_head->prev == null)
        ensures (freq_head->node_head != null) {
        var node_to_remove = freq_head->node_head;
        freq_head->remove_node (node_to_remove);
        key_to_node.unset (node_to_remove->key);
        size--;
        evicted (node_to_remove->key, node_to_remove->val);

        if (freq_head->is_empty) {
            // Because we never remove all elements:
            assert (freq_head->next != null);
            var empty_freq = freq_head;
            freq_head = freq_head->next;
            empty_freq->remove_self ();
            delete empty_freq;
        }
    }
}
