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

public class Life.HashLife.Cache.Frequency<K, V> : Object {

    public Frequency<K, V>? prev { get; set; }
    public Frequency<K, V>? next { get; set; }
    public ulong freq { get; set; }
    public Node<K, V>? node_head { get; set; }

    public bool is_empty {
        get { return node_head == null; }
    }

    public Frequency (ulong freq = 1) {
        Object (
            freq: freq,
            prev: null,
            next: null,
            node_head: null
        );
    }

    public void add_node (Node<K, V> node)
        requires (node.parent == null)
        requires (node.prev == null)
        requires (node.next == null)
        ensures (node.parent == this)
        ensures (node.prev == null)
        ensures (node_head == node)
    {
        node.parent = this;
        if (node_head != null) {
            node.next = node_head;
            node_head.prev = node;
        }

        node_head = node;
    }

    public void remove_node (Node<K, V> node)
        requires (node.parent == this)
        requires (node_head != null)
        ensures (node.parent == null)
        ensures (node.prev == null)
        ensures (node.next == null)
        ensures (node.next == null)
        ensures (node_head != node)
    {
        if (node.prev != null) {
            node.prev.next = node.next;
        }
        if (node.next != null) {
            node.next.prev = node.prev;
        }
        if (node_head == node) {
            node_head = node.next;
        }

        node.parent = null;
        node.prev = null;
        node.next = null;
    }

    public void remove_self ()
        ensures (prev == null)
        ensures (next == null)
    {
        if (prev != null) {
            prev.next = next;
        }
        if (next != null) {
            next.prev = prev;
        }

        prev = null;
        next = null;
    }
}
