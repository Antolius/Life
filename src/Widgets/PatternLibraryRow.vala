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

public class Life.Widgets.PatternLibraryRow : Gtk.ListBoxRow {

    private static Scaleable DEFAULT_SCALE = new ConstantScale ();

    public Pattern pattern { get; construct; }

    public PatternLibraryRow (Pattern pattern) {
        Object (
            pattern: pattern,
            margin: 8,
            activatable: false,
            selectable: false,
            can_focus: false,
            hexpand: true
        );
    }

    construct {
        var content = new Gtk.Grid () {
            row_spacing = 4
        };

        var name = new Gtk.Label (pattern.name) {
            xalign = 0f
        };
        name.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
        content.attach (name, 0, 0);
        Gtk.Widget last = name;

        var bottom = Gtk.PositionType.BOTTOM;
        var right = Gtk.PositionType.RIGHT;

        if (pattern.author != null) {
            var txt = _("Discovered by %s").printf (pattern.author);
            var author = new Gtk.Label (txt) {
                xalign = 0f
            };
            content.attach_next_to (author, last, bottom, 1, 1);
            last = author;

        }

        if (pattern.description != null) {
            var desc = new Gtk.Label (pattern.description) {
                xalign = 0f,
                wrap = true,
                wrap_mode = Pango.WrapMode.WORD,
                max_width_chars = 140
            };
            content.attach_next_to (desc, last, bottom, 1, 1);
            last = desc;

        }

        var board_margin = 8;
        var board = new DrawingBoard (DEFAULT_SCALE, pattern) {
            margin = board_margin
        };
        var scrolled_board = new Gtk.ScrolledWindow (null, null) {
            min_content_height = int.min(160, board.height + 2 * board_margin),
            max_content_height = 160,
            max_content_width = 240,
            child = board
        };
        var board_frame = new Gtk.Frame (null) {
            child = scrolled_board,
            margin_top = 4,
            margin_bottom = 4,
            hexpand = true
        };
        content.attach_next_to (board_frame, last, bottom, 1, 1);
        last = board_frame;

        if (pattern.link != null) {
            var label = _("Learn more");
            var link = new Gtk.LinkButton.with_label (pattern.link, label){
                halign = Gtk.Align.START
            };
            content.attach_next_to (link, last, bottom, 1, 1);
            last = link;
        }

        child = content;
        show_all ();
    }
}
