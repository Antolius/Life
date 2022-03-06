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
            title: Constants.SIMPLE_NAME,
            hexpand: true,
            halign: Gtk.Align.FILL
        );
    }

    construct {
        var tools = create_tool_buttons ();
        pack_start (tools);
        var clear = create_clear_button ();
        pack_start (clear);
        var menu = create_menu ();
        pack_end (menu);
    }

    private Gtk.ButtonBox create_tool_buttons () {
        var pencil_btn = new Gtk.ToggleButton () {
            active = state.active_tool == State.Tool.PENCIL,
            tooltip_text = _("Draw live cells"),
            image = new Gtk.Image.from_icon_name (
                "edit",
                Gtk.IconSize.SMALL_TOOLBAR
            )
        };
        var pencil_conn_id = pencil_btn.toggled.connect (() => {
            state.active_tool = pencil_btn.active
                ? State.Tool.PENCIL
                : State.Tool.POINTER;
        });

        var eraser_btn = new Gtk.ToggleButton () {
            active = state.active_tool == State.Tool.ERASER,
            tooltip_text = _("Erase live cells"),
            image = new Gtk.Image.from_icon_name (
                "edit-erase",
                Gtk.IconSize.SMALL_TOOLBAR
            )
        };
        var eraser_conn_id = eraser_btn.toggled.connect (() => {
            state.active_tool = eraser_btn.active
                ? State.Tool.ERASER
                : State.Tool.POINTER;
        });

        state.notify["active-tool"].connect (() => {
            SignalHandler.block (pencil_btn, pencil_conn_id);
            SignalHandler.block (eraser_btn, eraser_conn_id);
            pencil_btn.active = state.active_tool == State.Tool.PENCIL;
            eraser_btn.active = state.active_tool == State.Tool.ERASER;
            SignalHandler.unblock (pencil_btn, pencil_conn_id);
            SignalHandler.unblock (eraser_btn, eraser_conn_id);
        });

        var box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL) {
            layout_style = Gtk.ButtonBoxStyle.EXPAND
        };

        box.add (pencil_btn);
        box.add (eraser_btn);
        return box;
    }

    private Gtk.Button create_clear_button () {
        var btn = new Gtk.Button.from_icon_name (
            "edit-clear",
            Gtk.IconSize.SMALL_TOOLBAR
        ) {
            tooltip_text = _("Clear all")
        };
        btn.clicked.connect (state.clear);
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
            valign = Gtk.Align.START,
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
        scale.set_value (state.scale);
        scale.value_changed.connect (() => {
            state.scale = (int) scale.get_value ();
        });
        menu_grid.attach (scale, 1, 0, 2, 1);

        menu_grid.attach (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, 1, 3);

        var stats_toggle = new Gtk.ModelButton () {
            text = _("Toggle Stats")
        };
        stats_toggle.clicked.connect (() => {
            state.showing_stats = !state.showing_stats;
        });
        menu_grid.attach (stats_toggle, 0, 2, 3);

        menu_grid.show_all ();
        return new Gtk.MenuButton () {
            image = new Gtk.Image.from_icon_name (
                "open-menu",
                Gtk.IconSize.SMALL_TOOLBAR
            ),
            popover = new Gtk.Popover (null) {
                child = menu_grid
            }
        };
    }
}
