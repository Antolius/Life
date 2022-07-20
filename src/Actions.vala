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

namespace Life {

    // Groups
    public const string APP_GROUP = "app";
    public const string APP_PREFIX = APP_GROUP + ".";

    public const string WIN_GROUP = "win";
    public const string WIN_PREFIX = WIN_GROUP + ".";

    // Short action names (without group prefix)
    public const string ACTION_PLAY_PAUSE = "action-play-pause";
    public const string ACTION_STEP_FORWARD = "action-step-forward";
    public const string ACTION_SLOW_DOWN = "action-slow-down";
    public const string ACTION_SPEED_UP = "action-speed-up";

    // Full action names (with group prefix)
    public const string WIN_ACTION_PLAY_PAUSE = WIN_PREFIX + "action-play-pause";
    public const string WIN_ACTION_STEP_FORWARD = WIN_PREFIX + "action-step-forward";
    public const string WIN_ACTION_SLOW_DOWN = WIN_PREFIX + "action-slow-down";
    public const string WIN_ACTION_SPEED_UP = WIN_PREFIX + "action-speed-up";

    public string[] get_accels_for_action (string action_name) {
        var app = Application.get_default ();
        return app.get_accels_for_action (action_name);
    }

    public Gee.MultiMap<string, string> window_action_accelerators () {
        var accels = new Gee.HashMultiMap<string, string> ();
        accels[ACTION_PLAY_PAUSE] = "<Control>space";
        accels[ACTION_STEP_FORWARD] = "<Control>e";
        accels[ACTION_SLOW_DOWN] = "<Control>bracketleft";
        accels[ACTION_SPEED_UP] = "<Control>bracketright";
        return accels;
    }

    public Gee.List<SimpleAction> window_actions (State state) {
        var actions = new Gee.ArrayList<SimpleAction> ();

        var play_pause_action = new SimpleAction (ACTION_PLAY_PAUSE, null);
        play_pause_action.activate.connect (() => {
            state.is_playing = !state.is_playing;
        });
        state.bind_property (
            "editing-enabled",
            play_pause_action,
            "enabled",
            BindingFlags.SYNC_CREATE
        );
        actions.add (play_pause_action);

        var step_forward_action = new SimpleAction (ACTION_STEP_FORWARD, null);
        step_forward_action.activate.connect (() => {
            state.is_playing = false;
            state.step_by_one ();
        });
        state.bind_property (
            "editing-enabled",
            step_forward_action,
            "enabled",
            BindingFlags.SYNC_CREATE
        );
        actions.add (step_forward_action);

        var slow_down_action = new SimpleAction (ACTION_SLOW_DOWN, null);
        slow_down_action.activate.connect (() => {
            state.simulation_speed -= State.SPEED_STEP;
        });
        state.bind_property (
            "can-slow-down",
            slow_down_action,
            "enabled",
            BindingFlags.SYNC_CREATE
        );
        actions.add (slow_down_action);

        var speed_up_action = new SimpleAction (ACTION_SPEED_UP, null);
        speed_up_action.activate.connect (() => {
            state.simulation_speed += State.SPEED_STEP;
        });
        state.bind_property (
            "can-speed-up",
            speed_up_action,
            "enabled",
            BindingFlags.SYNC_CREATE
        );
        actions.add (speed_up_action);

        return actions;
    }
}
