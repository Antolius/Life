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

public class Life.Widgets.ScrolledBoard : Gtk.ScrolledWindow {

    public DrawingBoard drawing_board { get; construct; }

    private double? prev_width;
    private double? perv_height;

    public ScrolledBoard (DrawingBoard drawing_board) {
        Object (
            child: drawing_board,
            drawing_board: drawing_board
        );
    }

    construct {
        connect_signals ();
    }

    private void connect_signals () {
        drawing_board.draw.connect (on_child_draw);
    }

    private bool on_child_draw () {
        if (no_prev_state ()) {
            center_visible_section ();
        } else {
            maintain_visible_section ();
        }

        save_prev_state ();
        return true;
    }

    private bool no_prev_state () {
        return prev_width == null || perv_height == null;
    }

    private void center_visible_section () {
        var width = hadjustment.upper - hadjustment.lower;
        hadjustment.value = (width - hadjustment.page_size) / 2;
        var height = vadjustment.upper - vadjustment.lower;
        vadjustment.value = (height - vadjustment.page_size) / 2;
    }

    private void maintain_visible_section () {
        var width = hadjustment.upper - hadjustment.lower;
        var height = vadjustment.upper - vadjustment.lower;

        if (width != prev_width || height != perv_height) {
            hadjustment.value += (width - prev_width) / 2;
            vadjustment.value += (height - perv_height) / 2;
        }
    }

    private void save_prev_state () {
        prev_width = hadjustment.upper - hadjustment.lower;
        perv_height = vadjustment.upper - vadjustment.lower;
    }
}
