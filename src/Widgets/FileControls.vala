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

public class Life.Widgets.FileControls : Gtk.Bin {

    public State state { get; construct; }

    private Gtk.Popover menu_popover;

    public FileControls (State state) {
        Object (state: state);
    }

    construct {
        var title = new Granite.HeaderLabel ("");
        state.bind_property ("title", title, "label", BindingFlags.SYNC_CREATE);

        var caret = new Gtk.Image.from_icon_name (
            "pan-down-symbolic",
            Gtk.IconSize.MENU
        );

        var header_bar_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
        header_bar_box.pack_start (title);
        header_bar_box.pack_start (caret);

        var file_operation_indicator = new Gtk.Spinner () {
            tooltip_text = _("Saving to a file…")
        };
        state.notify["saving-in-progress"].connect (() => {
            if (state.saving_in_progress) {
                file_operation_indicator.tooltip_text = _("Saving to a file…");
                header_bar_box.pack_end (file_operation_indicator);
                file_operation_indicator.show_all ();
                file_operation_indicator.start ();
            } else {
                file_operation_indicator.stop ();
                header_bar_box.remove (file_operation_indicator);
            }
        });
        state.notify["opening-in-progress"].connect (() => {
            if (state.opening_in_progress) {
                file_operation_indicator.tooltip_text = _("Opening a file…");
                header_bar_box.pack_end (file_operation_indicator);
                file_operation_indicator.show_all ();
                file_operation_indicator.start ();
            } else {
                file_operation_indicator.stop ();
                header_bar_box.remove (file_operation_indicator);
            }
        });

        var menu_grid = new Gtk.Grid () {
            margin_top = 3,
            margin_bottom = 3,
            orientation = Gtk.Orientation.VERTICAL
        };
        menu_grid.add (create_open_button ());
        menu_grid.add (create_save_button ());
        menu_grid.add (create_save_as_button ());
        menu_grid.show_all ();

        menu_popover = new Gtk.Popover (null) {
            child = menu_grid
        };

        var title_button = new Gtk.MenuButton () {
            child = header_bar_box,
            relief = Gtk.ReliefStyle.NONE,
            popover = menu_popover
        };
        title_button.clicked.connect (() => {
            caret.clear ();
            caret.set_from_icon_name (
                title_button.active ? "pan-up-symbolic" : "pan-down-symbolic",
                Gtk.IconSize.MENU
            );
            caret.show_all ();
        });

        child = title_button;
    }

    private Gtk.ModelButton create_open_button () {
        return create_file_op_button (
            "document-open",
            _("Open a File"),
            WIN_ACTION_OPEN_FILE
        );
    }

    private Gtk.Button create_save_button () {
        return create_file_op_button (
            "document-save",
            _("Save this File"),
            WIN_ACTION_SAVE_FILE
        );
    }

    private Gtk.Button create_save_as_button () {
        return create_file_op_button (
            "document-save-as",
            _("Save to a Different File"),
            WIN_ACTION_SAVE_AS_FILE
        );
    }

    private Gtk.ModelButton create_file_op_button (
        string icon,
        string label,
        string action
    ) {
        var btn = new Gtk.ModelButton () {
            action_name = action
        };
        btn.get_child ().destroy ();

        var content = new Gtk.Grid () {
            column_spacing = 8,
            valign = Gtk.Align.BASELINE,
            orientation = Gtk.Orientation.HORIZONTAL
        };
        content.add (new Gtk.Image () {
            gicon = new ThemedIcon (icon),
            icon_size = Gtk.IconSize.LARGE_TOOLBAR
        });
        content.add (new Granite.AccelLabel.from_action_name (
            label, action
        ));
        btn.add (content);

        return btn;
    }
}
