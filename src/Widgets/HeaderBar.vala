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

public class Life.Widgets.HeaderBar : Hdy.HeaderBar {

    public State state { get; construct; }

    public HeaderBar (State state) {
        Object (
            state: state,
            has_subtitle: false,
            show_close_button: true,
            hexpand: true,
            halign: Gtk.Align.FILL
        );
    }

    construct {
        var library_expander = create_library_expander_button ();
        pack_start (library_expander);
        var tools = create_tool_buttons ();
        pack_start (tools);
        var clear = create_clear_button ();
        pack_start (clear);

        custom_title = new FileControls (state);

        var menu = create_menu ();
        pack_end (menu);
    }

    private Gtk.Button create_library_expander_button () {
        var show_tooltip = Granite.markup_accel_tooltip (
            get_accels_for_action (WIN_ACTION_TOGGLE_LIBRARY),
            _("Show Patterns Library")
        );
        var hide_tooltip = Granite.markup_accel_tooltip (
            get_accels_for_action (WIN_ACTION_TOGGLE_LIBRARY),
            _("Hide Patterns Library")
        );
        var initial_tooltip = (state.library_position > 0)
            ? hide_tooltip : show_tooltip;
        var btn = new Gtk.Button.from_icon_name (
            "accessories-dictionary",
            Gtk.IconSize.LARGE_TOOLBAR
        ) {
            action_name = WIN_ACTION_TOGGLE_LIBRARY,
            tooltip_markup = initial_tooltip,
            margin_end = 16
        };

        state.notify["library-position"].connect (() => {
            var library_is_hidden = state.library_position == 0;
            var showing_hidden_tooltip = btn.tooltip_markup == hide_tooltip;
            if (library_is_hidden && showing_hidden_tooltip) {
                btn.tooltip_markup = show_tooltip;
            } else if (!library_is_hidden && !showing_hidden_tooltip) {
                btn.tooltip_markup = hide_tooltip;
            }
        });

        return btn;
    }

    private Gtk.ButtonBox create_tool_buttons () {
        var pointer_btn = new Gtk.ToggleButton () {
            active = state.active_tool == State.Tool.POINTER,
            tooltip_markup = Granite.markup_accel_tooltip (
                get_accels_for_action (WIN_ACTION_POINTER_TOOL),
                _("Select cells")
            ),
            image = new Gtk.Image.from_icon_name (
                "pointer-symbolic",
                Gtk.IconSize.BUTTON
            )
        };
        var pointer_conn_id = pointer_btn.toggled.connect (() => {
            if (pointer_btn.active) {
                state.active_tool = State.Tool.POINTER;
            } else {
                pointer_btn.active = true;
            }
        });

        var pencil_btn = new Gtk.ToggleButton () {
            active = state.active_tool == State.Tool.PENCIL,
            tooltip_markup = Granite.markup_accel_tooltip (
                get_accels_for_action (WIN_ACTION_PENCIL_TOOL),
                _("Draw live cells")
            ),
            image = new Gtk.Image.from_icon_name (
                "edit-symbolic",
                Gtk.IconSize.BUTTON
            )
        };
        var pencil_conn_id = pencil_btn.toggled.connect (() => {
            if (pencil_btn.active) {
                state.active_tool = State.Tool.PENCIL;
            } else {
                pencil_btn.active = true;
            }
        });

        var eraser_btn = new Gtk.ToggleButton () {
            active = state.active_tool == State.Tool.ERASER,
            tooltip_markup = Granite.markup_accel_tooltip (
                get_accels_for_action (WIN_ACTION_ERASER_TOOL),
                _("Erase live cells")
            ),
            image = new Gtk.Image.from_icon_name (
                "edit-erase-symbolic",
                Gtk.IconSize.BUTTON
            )
        };
        var eraser_conn_id = eraser_btn.toggled.connect (() => {
            if (eraser_btn.active) {
                state.active_tool = State.Tool.ERASER;
            } else {
                eraser_btn.active = true;
            }
        });

        state.notify["active-tool"].connect (() => {
            SignalHandler.block (pointer_btn, pointer_conn_id);
            SignalHandler.block (pencil_btn, pencil_conn_id);
            SignalHandler.block (eraser_btn, eraser_conn_id);
            pointer_btn.active = state.active_tool == State.Tool.POINTER;
            pencil_btn.active = state.active_tool == State.Tool.PENCIL;
            eraser_btn.active = state.active_tool == State.Tool.ERASER;
            SignalHandler.unblock (pointer_btn, pointer_conn_id);
            SignalHandler.unblock (pencil_btn, pencil_conn_id);
            SignalHandler.unblock (eraser_btn, eraser_conn_id);
        });

        var box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL) {
            layout_style = Gtk.ButtonBoxStyle.EXPAND,
            sensitive = state.editing_enabled,
            valign = Gtk.Align.CENTER,
            expand = false
        };

        state.bind_property (
            "editing-enabled",
            box,
            "sensitive",
            BindingFlags.DEFAULT
        );

        box.add (pointer_btn);
        box.add (pencil_btn);
        box.add (eraser_btn);
        return box;
    }

    private Gtk.Button create_clear_button () {
        var btn = new Gtk.Button.from_icon_name (
            "edit-clear",
            Gtk.IconSize.LARGE_TOOLBAR
        ) {
            action_name = WIN_ACTION_CLEAR_ALL,
            tooltip_markup = Granite.markup_accel_tooltip (
                get_accels_for_action (WIN_ACTION_CLEAR_ALL),
                _("Clear all")
            ),
            margin_start = 16
        };

        return btn;
    }

    private Gtk.MenuButton create_menu () {
        var menu_grid = new Gtk.Grid () {
            margin_bottom = 4,
            row_homogeneous = false,
            orientation = Gtk.Orientation.VERTICAL,
            width_request = 200
        };

        var scale_label = new Gtk.Label (_("Scale")) {
            justify = Gtk.Justification.RIGHT,
            valign = Gtk.Align.CENTER,
            margin = 8,
        };
        menu_grid.attach (scale_label, 0, 0, 1, 1);
        var scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 5, 40, 5) {
            digits = 0,
            draw_value = true,
            value_pos = Gtk.PositionType.BOTTOM,
            hexpand = true,
            margin = 8,
        };
        scale.add_mark (5, Gtk.PositionType.BOTTOM, null);
        scale.add_mark (10, Gtk.PositionType.BOTTOM, null);
        scale.add_mark (20, Gtk.PositionType.BOTTOM, null);
        scale.add_mark (30, Gtk.PositionType.BOTTOM, null);
        scale.add_mark (40, Gtk.PositionType.BOTTOM, null);
        scale.set_value (state.board_scale);
        scale.value_changed.connect (() => {
            state.board_scale = (int) scale.get_value ();
        });
        menu_grid.attach (scale, 1, 0, 2, 1);

        menu_grid.attach (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, 1, 3);

        var autosave_switch = new Granite.SwitchModelButton (_("Autosave"));
        state.bind_property (
            "autosave",
            autosave_switch,
            "active",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE
        );
        menu_grid.attach (autosave_switch, 0, 2, 3);

        var stats_switch = new Granite.SwitchModelButton (_("Statistics"));
        state.bind_property (
            "showing_stats",
            stats_switch,
            "active",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE
        );
        menu_grid.attach (stats_switch, 0, 3, 3);

        menu_grid.attach (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, 4, 3);

        var help_btn = new Gtk.ModelButton () {
            action_name = WIN_ACTION_SHOW_HELP
        };
        help_btn.get_child ().destroy ();
        help_btn.add(new Granite.AccelLabel.from_action_name (
            _("Open Game of Life Primer"), WIN_ACTION_SHOW_HELP
        ));
        menu_grid.attach (help_btn, 0, 5, 3);

        menu_grid.show_all ();
        return new Gtk.MenuButton () {
            image = new Gtk.Image.from_icon_name (
                "open-menu",
                Gtk.IconSize.LARGE_TOOLBAR
            ),
            popover = new Gtk.Popover (null) {
                child = menu_grid
            }
        };
    }
}
