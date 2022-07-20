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
    public const string ACTION_TOGGLE_LIBRARY = "action-toggle-library";
    public const string ACTION_POINTER_TOOL = "action-pointer-tool";
    public const string ACTION_PENCIL_TOOL = "action-pencil-tool";
    public const string ACTION_ERASER_TOOL = "action-eraser-tool";
    public const string ACTION_CLEAR_ALL = "action-clear-all";
    public const string ACTION_SHOW_HELP = "action-show-help";

    // Full action names (with group prefix)
    public const string WIN_ACTION_PLAY_PAUSE = WIN_PREFIX + ACTION_PLAY_PAUSE;
    public const string WIN_ACTION_STEP_FORWARD = WIN_PREFIX + ACTION_STEP_FORWARD;
    public const string WIN_ACTION_SLOW_DOWN = WIN_PREFIX + ACTION_SLOW_DOWN;
    public const string WIN_ACTION_SPEED_UP = WIN_PREFIX + ACTION_SPEED_UP;
    public const string WIN_ACTION_TOGGLE_LIBRARY = WIN_PREFIX + ACTION_TOGGLE_LIBRARY;
    public const string WIN_ACTION_POINTER_TOOL = WIN_PREFIX + ACTION_POINTER_TOOL;
    public const string WIN_ACTION_PENCIL_TOOL = WIN_PREFIX + ACTION_PENCIL_TOOL;
    public const string WIN_ACTION_ERASER_TOOL = WIN_PREFIX + ACTION_ERASER_TOOL;
    public const string WIN_ACTION_CLEAR_ALL = WIN_PREFIX + ACTION_CLEAR_ALL;
    public const string WIN_ACTION_SHOW_HELP = WIN_PREFIX + ACTION_SHOW_HELP;

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
        accels[ACTION_TOGGLE_LIBRARY] = "<Control>backslash";
        accels[ACTION_POINTER_TOOL] = "<Control>1";
        accels[ACTION_PENCIL_TOOL] = "<Control>2";
        accels[ACTION_ERASER_TOOL] = "<Control>3";
        accels[ACTION_CLEAR_ALL] = "<Control><Shift>k";
        accels[ACTION_SHOW_HELP] = "F1";
        return accels;
    }

    public Gee.List<SimpleAction> window_actions (State state) {
        var actions = new Gee.ArrayList<SimpleAction> ();

        // Playback actions
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

        // Library pane actions
        var toggle_library_action = new SimpleAction (ACTION_TOGGLE_LIBRARY, null);
        toggle_library_action.activate.connect (() => {
            if (state.library_position > 0) {
                state.animate_library_pane_closing ();
            } else {
                state.animate_library_pane_opening ();
            }
        });
        state.bind_property (
            "library-animation-in-progress",
            toggle_library_action,
            "enabled",
            BindingFlags.SYNC_CREATE,
            (bind, source, ref target) => {
                target.set_boolean (!source.get_boolean ());
                return true;
            }
        );
        actions.add (toggle_library_action);

        // Editing actions
        var pointer_tool_action = new SimpleAction (ACTION_POINTER_TOOL, null);
        pointer_tool_action.activate.connect (() => {
            state.active_tool = State.Tool.POINTER;
        });
        state.bind_property (
            "editing-enabled",
            pointer_tool_action,
            "enabled",
            BindingFlags.SYNC_CREATE
        );
        actions.add (pointer_tool_action);

        var pencil_tool_action = new SimpleAction (ACTION_PENCIL_TOOL, null);
        pencil_tool_action.activate.connect (() => {
            state.active_tool = State.Tool.PENCIL;
        });
        state.bind_property (
            "editing-enabled",
            pencil_tool_action,
            "enabled",
            BindingFlags.SYNC_CREATE
        );
        actions.add (pencil_tool_action);

        var eraser_tool_action = new SimpleAction (ACTION_ERASER_TOOL, null);
        eraser_tool_action.activate.connect (() => {
            state.active_tool = State.Tool.ERASER;
        });
        state.bind_property (
            "editing-enabled",
            eraser_tool_action,
            "enabled",
            BindingFlags.SYNC_CREATE
        );
        actions.add (eraser_tool_action);

        var clear_all_action = new SimpleAction (ACTION_CLEAR_ALL, null);
        clear_all_action.activate.connect (state.clear);
        state.bind_property (
            "editing-enabled",
            clear_all_action,
            "enabled",
            BindingFlags.SYNC_CREATE
        );
        actions.add (clear_all_action);

        // Help
        var show_help_action = new SimpleAction (ACTION_SHOW_HELP, null);
        show_help_action.activate.connect (() => {
            var dialog = new Widgets.OnboardingDialog ();
            dialog.run ();
            dialog.destroy ();
        });
        actions.add (show_help_action);

        return actions;
    }
}
