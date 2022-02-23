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
    private const int SPEED_STEP = 4;

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
        var btn = new Gtk.Button.from_icon_name (
            "media-seek-backward",
            Gtk.IconSize.SMALL_TOOLBAR
        ) {
            tooltip_text = _("Slow simulation down"),
            sensitive = can_slow_down ()
        };
        btn.clicked.connect (() => {
            if (can_slow_down ()) {
                state.speed -= SPEED_STEP;
            }
        });
        state.notify["speed"].connect (() => {
            btn.sensitive = can_slow_down ();
        });
        state.notify["is-playing"].connect (() => {
            btn.sensitive = can_slow_down ();
        });
        return btn;
    }

    private bool can_slow_down () {
        return state.is_playing && state.speed - SPEED_STEP > State.MIN_SPEED;
    }

    private Gtk.Button create_play_button () {
        var play_tooltip = _("Run simulation");
        var play_icon = new Gtk.Image.from_icon_name (
            "media-playback-start",
            Gtk.IconSize.SMALL_TOOLBAR
        );

        var pause_tooltip = _("Pause simulation");
        var pause_icon = new Gtk.Image.from_icon_name (
            "media-playback-pause",
            Gtk.IconSize.SMALL_TOOLBAR
        );

        var btn = new Gtk.Button () {
            image = state.is_playing ? pause_icon : play_icon,
            tooltip_text = state.is_playing ? pause_tooltip : play_tooltip
        };
        btn.clicked.connect (() => {
            state.is_playing = !state.is_playing;
        });
        state.notify["is-playing"].connect (() => {
            btn.image = state.is_playing ? pause_icon : play_icon;
            btn.tooltip_text = state.is_playing ? pause_tooltip : play_tooltip;
            btn.show_all ();
        });

        return btn;
    }

    private Gtk.Button create_speed_up_button () {
        var btn = new Gtk.Button.from_icon_name (
            "media-seek-forward",
            Gtk.IconSize.SMALL_TOOLBAR
        ) {
            tooltip_text = _("Speed simulation up"),
            sensitive = can_speed_up ()
        };
        btn.clicked.connect (() => {
            if (can_speed_up ()) {
                state.speed += SPEED_STEP;
            }
        });
        state.notify["speed"].connect (() => {
            btn.sensitive = can_speed_up ();
        });
        state.notify["is-playing"].connect (() => {
            btn.sensitive = can_speed_up ();
        });
        return btn;
    }

    private bool can_speed_up () {
        return state.is_playing && state.speed + SPEED_STEP < State.MAX_SPEED;
    }

    private Gtk.Button create_step_forward_button () {
        var btn = new Gtk.Button.from_icon_name (
            "media-skip-forward",
            Gtk.IconSize.SMALL_TOOLBAR
        ) {
            tooltip_text = _("Advance simulation by one generation")
        };
        btn.clicked.connect (() => {
            state.is_playing = false;
            state.tick ();
        });
        return btn;
    }

    private Gtk.Label create_generation_counter () {
        var counter = new Gtk.Label (generation_txt ());
        state.tick.connect (() => {
            counter.label = generation_txt ();
        });
        return counter;
    }

    private string generation_txt () {
        return _("Generation %" + int64.FORMAT).printf (state.generation);
    }
}
