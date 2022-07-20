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
    public const string ACTION_OPEN_FILE = "action-open-file";
    public const string ACTION_SAVE_FILE = "action-save-file";
    public const string ACTION_SAVE_AS_FILE = "action-save-as-file";
    public const string ACTION_OPEN_AUTOSAVE = "action-open-autosave";

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
    public const string WIN_ACTION_OPEN_FILE = WIN_PREFIX + ACTION_OPEN_FILE;
    public const string WIN_ACTION_SAVE_FILE = WIN_PREFIX + ACTION_SAVE_FILE;
    public const string WIN_ACTION_SAVE_AS_FILE = WIN_PREFIX + ACTION_SAVE_AS_FILE;
    public const string WIN_ACTION_OPEN_AUTOSAVE = WIN_PREFIX + ACTION_OPEN_AUTOSAVE;

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
        accels[ACTION_OPEN_FILE] = "<Control>o";
        accels[ACTION_SAVE_FILE] = "<Control>s";
        accels[ACTION_SAVE_AS_FILE] = "<Control><Shift>s";
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
            BindingFlags.SYNC_CREATE | BindingFlags.INVERT_BOOLEAN
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

        // Help actions
        var show_help_action = new SimpleAction (ACTION_SHOW_HELP, null);
        show_help_action.activate.connect (() => {
            var dialog = new Widgets.OnboardingDialog ();
            dialog.run ();
            dialog.destroy ();
        });
        actions.add (show_help_action);

        // File actions
        var open_file_action = new SimpleAction (ACTION_OPEN_FILE, null);
        open_file_action.set_enabled (true); // Activated from Welcome screen
        open_file_action.activate.connect (() => on_open (state));
        state.bind_property (
            "editing-enabled",
            open_file_action,
            "enabled",
            BindingFlags.DEFAULT
        );
        actions.add (open_file_action);

        var save_file_action = new SimpleAction (ACTION_SAVE_FILE, null);
        save_file_action.activate.connect (() => on_save (state));
        state.bind_property (
            "editing-enabled",
            save_file_action,
            "enabled",
            BindingFlags.SYNC_CREATE
        );
        actions.add (save_file_action);

        var save_as_file_action = new SimpleAction (ACTION_SAVE_AS_FILE, null);
        save_as_file_action.activate.connect (() => on_save_as (state));
        state.bind_property (
            "editing-enabled",
            save_as_file_action,
            "enabled",
            BindingFlags.SYNC_CREATE
        );
        actions.add (save_as_file_action);

        var open_autosave_action = new SimpleAction (ACTION_OPEN_AUTOSAVE, null);
        open_autosave_action.set_enabled (true); // Activated from Welcome screen
        open_autosave_action.activate.connect (() => on_open_autosave (state));
        state.bind_property (
            "editing-enabled",
            open_autosave_action,
            "enabled",
            BindingFlags.DEFAULT
        );
        actions.add (open_autosave_action);

        return actions;
    }

    private void on_open (State state) {
        var dialog = new Gtk.FileChooserNative (
            null,
            null,
            Gtk.FileChooserAction.OPEN,
            null,
            null
        ) {
            filter = cells_filter ()
        };

        var res = dialog.run ();
        if (res == Gtk.ResponseType.ACCEPT) {
            var path = dialog.get_filename ();
            if (path == null) {
                state.info (new InfoModel (
                    _("Cannot open the selected file"),
                    Gtk.MessageType.WARNING,
                    _("Try Opening a Different File"),
                    () => on_open (state)
                ));
                return;
            }

            state.showing_welcome = false;
            state.open.begin (path, (obj, res) => {
                var ok = state.open.end (res);
                if (!ok) {
                    state.info (new InfoModel (
                        _("Reading a pattern from the selected file has failed"),
                        Gtk.MessageType.ERROR,
                        _("Try Opening a Different File"),
                        () => on_open (state)
                    ));
                } else {
                  state.clear_info ();
                }
            });
        }
    }

    private void on_save (State state) {
        if (state.file != null) {
            state.save.begin (null, (obj, res) => {
                var ok = state.save.end (res);
                if (!ok) {
                    state.info (new InfoModel (
                        _("Writing into the current file has failed"),
                        Gtk.MessageType.ERROR,
                        _("Try Saving Under a New Name"),
                        () => on_save_as (state)
                    ));
                } else {
                  state.clear_info ();
                }
            });
        } else {
            on_save_as (state);
        }
    }

    private void on_save_as (State state) {
        var dialog = new Gtk.FileChooserNative (
            null,
            null,
            Gtk.FileChooserAction.SAVE,
            null,
            null
        ) {
            filter = cells_filter ()
        };
        dialog.set_do_overwrite_confirmation (true);

        var res = dialog.run ();
        if (res == Gtk.ResponseType.ACCEPT) {
            var path = dialog.get_filename ();
            if (path == null) {
                state.info (new InfoModel (
                    _("Cannot save into the selected file"),
                    Gtk.MessageType.WARNING,
                    _("Try Saving Under a New Name"),
                    () => on_save_as (state)
                ));
                return;
            }

            state.save.begin (path, (obj, res) => {
                var ok = state.save.end (res);
                if (!ok) {
                    state.info (new Life.InfoModel (
                        _("Writing into the selected file has failed"),
                        Gtk.MessageType.ERROR,
                        _("Try Saving Under a New Name"),
                        () => on_save_as (state)
                    ));
                } else {
                  state.clear_info ();
                }
            });
        }
    }

    private void on_open_autosave (State state) {
        state.showing_welcome = false;
        state.open_autosave.begin ((obj, res) => {
            var ok = state.open_autosave.end (res);
            if (!ok) {
                state.info (new InfoModel (
                    _("Reading a pattern from the autosave file has failed"),
                    Gtk.MessageType.ERROR,
                    _("Try Opening a Different File"),
                    () => on_open (state)
                ));
            } else {
              state.clear_info ();
            }
        });
    }

    private Gtk.FileFilter cells_filter () {
        var cells_filter = new Gtk.FileFilter ();
        cells_filter.set_filter_name (_("Cells files"));
        cells_filter.add_pattern ("*.cells");
        return cells_filter;
    }
}
