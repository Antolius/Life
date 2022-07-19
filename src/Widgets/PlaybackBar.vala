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

public class Life.Widgets.PlaybackBar : Gtk.ActionBar {

    public State state { get; construct; }

    public PlaybackBar (State state) {
        Object (state: state);
    }

    construct {
        var slow_down_btn = create_slow_down_button ();
        pack_start (slow_down_btn);
        var play_btn = create_play_button ();
        pack_start (play_btn);
        var speed_up_btn = create_speed_up_button ();
        pack_start (speed_up_btn);
        var step_forward_btn = create_step_forward_button ();
        pack_start (step_forward_btn);

        var generation_counter = create_generation_counter ();
        pack_end (generation_counter);
    }

    private Gtk.Button create_slow_down_button () {
        var action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_SLOW_DOWN;
        var btn = new Gtk.Button.from_icon_name (
            "media-seek-backward",
            Gtk.IconSize.SMALL_TOOLBAR
        ) {
            action_name = action_name,
            tooltip_markup = Granite.markup_accel_tooltip (
                get_accels_for_action (action_name),
                _("Slow simulation down")
            )
        };

        return btn;
    }

    private Gtk.Button create_play_button () {
        var action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_PLAY_PAUSE;
        var play_tooltip = Granite.markup_accel_tooltip (
            get_accels_for_action (action_name),
            _("Run simulation")
        );
        var play_icon = new Gtk.Image.from_icon_name (
            "media-playback-start",
            Gtk.IconSize.LARGE_TOOLBAR
        );

        var pause_tooltip = Granite.markup_accel_tooltip (
            get_accels_for_action (action_name),
            _("Pause simulation")
        );
        var pause_icon = new Gtk.Image.from_icon_name (
            "media-playback-pause",
            Gtk.IconSize.LARGE_TOOLBAR
        );

        var btn = new Gtk.Button () {
            action_name = action_name,
            image = state.is_playing ? pause_icon : play_icon,
            tooltip_markup = state.is_playing ? pause_tooltip : play_tooltip
        };

        state.notify["is-playing"].connect (() => {
            btn.image = state.is_playing ? pause_icon : play_icon;
            btn.tooltip_markup = state.is_playing ? pause_tooltip : play_tooltip;
            btn.show_all ();
        });

        return btn;
    }

    private Gtk.Button create_speed_up_button () {
        var action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_SPEED_UP;
        var btn = new Gtk.Button.from_icon_name (
            "media-seek-forward",
            Gtk.IconSize.SMALL_TOOLBAR
        ) {
            action_name = action_name,
            tooltip_markup = Granite.markup_accel_tooltip (
                get_accels_for_action (action_name),
                _("Speed simulation up")
            )
        };

        return btn;
    }

    private Gtk.Button create_step_forward_button () {
        var action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_STEP_FORWARD;
        var btn = new Gtk.Button.from_icon_name (
            "media-skip-forward",
            Gtk.IconSize.SMALL_TOOLBAR
        ) {
            action_name = action_name,
            tooltip_markup = Granite.markup_accel_tooltip (
                get_accels_for_action (action_name),
                _("Advance simulation by one generation")
            )
        };

        return btn;
    }

    private Gtk.Label create_generation_counter () {
        var counter = new Gtk.Label (generation_txt ());
        state.simulation_updated.connect (() => {
            counter.label = generation_txt ();
        });
        return counter;
    }

    private string generation_txt () {
        return _("Generation %" + int64.FORMAT).printf (state.generation);
    }

    private string[] get_accels_for_action (string action_name) {
        var app = (Application) GLib.Application.get_default ();
        return app.get_accels_for_action (action_name);
    }
}
