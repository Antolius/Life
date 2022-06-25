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

    private static Scaleable default_scale = new ConstantScale ();

    public Pattern pattern { get; construct; }
    public State state { get; construct; }

    public PatternLibraryRow (Pattern pattern, State state) {
        Object (
            pattern: pattern,
            state: state,
            margin: 8,
            margin_bottom: 16,
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

        var board_grid = new Gtk.Grid ();

        var board_margin = 8;
        var board = new DrawingBoard (default_scale, pattern) {
            margin = board_margin
        };
        board.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK);
        board.add_events (Gdk.EventMask.LEAVE_NOTIFY_MASK);
        board.enter_notify_event.connect (event => {
            var window = board.get_window ();
            if (window != null) {
                window.set_cursor (new Gdk.Cursor.from_name (
                    window.get_display (),
                    "grab"
                ));
            }
        });
        board.leave_notify_event.connect (event => {
            var window = board.get_window ();
            if (window != null) {
                window.set_cursor (new Gdk.Cursor.from_name (
                    window.get_display (),
                    "none"
                ));
            }
        });
        Gtk.drag_source_set (
            board,
            Gdk.ModifierType.BUTTON1_MASK,
            EditingBoard.TARGET_ENTRIES,
            Gdk.DragAction.COPY
        );
        board.drag_data_get.connect ((ctx, data, info, time_) => {
            var pattern_data = new uchar[(sizeof (Pattern))];
            ((Pattern[])pattern_data)[0] = pattern;
            var pattern_atom = Gdk.Atom.intern_static_string (Constants.PATTERN);
            data.set (pattern_atom, 0, pattern_data);
        });

        var scrolled_board = new Gtk.ScrolledWindow (null, null) {
            min_content_height = int.min (160, board.height + 2 * board_margin),
            max_content_height = 160,
            max_content_width = 240,
            child = board
        };
        board_grid.attach (scrolled_board, 0, 0);

        var actions = new Gtk.ActionBar ();

        var flip_horizontally_btn = new Gtk.Button.from_icon_name (
            "object-flip-horizontal-symbolic",
            Gtk.IconSize.SMALL_TOOLBAR
        ) {
            tooltip_text = _("Flip horizontally"),
        };
        flip_horizontally_btn.clicked.connect (() => {
            pattern.flip_horizontally ();
            board.queue_draw ();
        });
        actions.pack_start (flip_horizontally_btn);

        var flip_vertically_btn = new Gtk.Button.from_icon_name (
            "object-flip-vertical-symbolic",
            Gtk.IconSize.SMALL_TOOLBAR
        ) {
            tooltip_text = _("Flip vertically"),
        };
        flip_vertically_btn.clicked.connect (() => {
            pattern.flip_vertically ();
            board.queue_draw ();
        });
        actions.pack_start (flip_vertically_btn);

        var rotate_clockwise = new Gtk.Button.from_icon_name (
            "object-rotate-right-symbolic",
            Gtk.IconSize.SMALL_TOOLBAR
        ) {
            tooltip_text = _("Rotate clockwise"),
        };
        rotate_clockwise.clicked.connect (() => {
            pattern.rotate_clockwise ();
            board.queue_resize ();
            board.queue_draw ();
            var new_height = int.min (160, board.height + 2 * board_margin);
            scrolled_board.min_content_height = new_height;
        });
        actions.pack_start (rotate_clockwise);

        var rotate_counter_clockwise = new Gtk.Button.from_icon_name (
            "object-rotate-left-symbolic",
            Gtk.IconSize.SMALL_TOOLBAR
        ) {
            tooltip_text = _("Rotate counter-clockwise"),
        };
        rotate_counter_clockwise.clicked.connect (() => {
            pattern.rotate_counter_clockwise ();
            board.queue_resize ();
            board.queue_draw ();
            var new_height = int.min (160, board.height + 2 * board_margin);
            scrolled_board.min_content_height = new_height;
        });
        actions.pack_start (rotate_counter_clockwise);

        var load_btn = new Gtk.Button.from_icon_name (
            "document-export-symbolic",
            Gtk.IconSize.SMALL_TOOLBAR
        ) {
            tooltip_text = _("Load into simulation"),
        };
        load_btn.clicked.connect (() => {
            if (!state.editable.is_empty ()) {
                state.clear ();
            }

            pattern.write_into_centered.begin (state.editable, true, (obj, res) => {
                pattern.write_into_centered.end (res);

                state.simulation_updated ();
            });
        });

        state.notify["saving-in-progress"].connect (() => {
            load_btn.sensitive = !state.saving_in_progress && !state.opening_in_progress;
        });
        state.notify["opening-in-progress"].connect (() => {
            load_btn.sensitive = !state.saving_in_progress && !state.opening_in_progress;
        });

        actions.pack_end (load_btn);

        board_grid.attach (actions, 0, 1);
        var board_frame = new Gtk.Frame (null) {
            child = board_grid,
            margin_top = 4,
            margin_bottom = 4,
            hexpand = true
        };
        content.attach_next_to (board_frame, last, bottom, 1, 1);
        last = board_frame;

        if (pattern.link != null) {
            var label = _("Learn more");
            var link = new Gtk.LinkButton.with_label (pattern.link, label) {
                halign = Gtk.Align.START
            };
            content.attach_next_to (link, last, bottom, 1, 1);
            last = link;
        }

        child = content;
        show_all ();
    }
}
