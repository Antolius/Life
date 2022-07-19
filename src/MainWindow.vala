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

public class Life.MainWindow : Hdy.ApplicationWindow {

    public const string ACTION_GROUP_PREFIX = "win";
    public const string ACTION_PREFIX = ACTION_GROUP_PREFIX + ".";

    public const string ACTION_PLAY_PAUSE = "action-play-pause";
    public const string ACTION_STEP_FORWARD = "action-step-forward";
    public const string ACTION_SLOW_DOWN = "action-slow-down";
    public const string ACTION_SPEED_UP = "action-speed-up";

    public State state { get; construct; }

    private Gee.MultiMap<Action, string> action_accelerators =
        new Gee.HashMultiMap<Action, string> ();

    private Gtk.Grid grid;
    private uint configure_id;

    public MainWindow (State state, Application application) {
        Object (
            state: state,
            application: application,
            title: Constants.SIMPLE_NAME
        );
    }

    static construct {
        load_style ();
    }

    private static void load_style () {
        var provider = new Gtk.CssProvider ();
        var resource_name = Constants.resource_base () + "/style.css";
        provider.load_from_resource (resource_name);
        var screen = Gdk.Screen.get_default ();
        Gtk.StyleContext.add_provider_for_screen (
            screen,
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }

    construct {
        apply_saved_window_state ();
        create_actions ();
        register_actions ();
        create_layout ();
        show_all ();
    }

    private void apply_saved_window_state () {
        int window_x, window_y;
        var rect = Gtk.Allocation ();

        Application.settings.get ("window-position", "(ii)", out window_x, out window_y);
        Application.settings.get ("window-size", "(ii)", out rect.width, out rect.height);

        if (window_x != -1 || window_y != -1) {
            move (window_x, window_y);
        }

        set_allocation (rect);

        if (Application.settings.get_boolean ("window-maximized")) {
            maximize ();
        }
    }

    public override bool configure_event (Gdk.EventConfigure event) {
        if (configure_id != 0) {
            GLib.Source.remove (configure_id);
        }

        configure_id = Timeout.add (100, () => {
            configure_id = 0;

            if (is_maximized) {
                Application.settings.set_boolean ("window-maximized", true);
            } else {
                Application.settings.set_boolean ("window-maximized", false);

                Gdk.Rectangle rect;
                get_allocation (out rect);
                Application.settings.set ("window-size", "(ii)", rect.width, rect.height);

                int root_x, root_y;
                get_position (out root_x, out root_y);
                Application.settings.set ("window-position", "(ii)", root_x, root_y);
            }

            return false;
        });

        return base.configure_event (event);
    }

    private void create_actions () {
        var play_pause_action = new SimpleAction (ACTION_PLAY_PAUSE, null);
        play_pause_action.activate.connect (on_play_pause);
        state.bind_property (
            "editing-enabled",
            play_pause_action,
            "enabled",
            BindingFlags.SYNC_CREATE
        );
        action_accelerators[play_pause_action] = "<Control>space";

        var step_forward_action = new SimpleAction (ACTION_STEP_FORWARD, null);
        step_forward_action.activate.connect (on_step_forward);
        state.bind_property (
            "editing-enabled",
            step_forward_action,
            "enabled",
            BindingFlags.SYNC_CREATE
        );
        action_accelerators[step_forward_action] = "<Control>e";

        var slow_down_action = new SimpleAction (ACTION_SLOW_DOWN, null);
        slow_down_action.activate.connect (on_slow_down);
        state.bind_property (
            "can-slow-down",
            slow_down_action,
            "enabled",
            BindingFlags.SYNC_CREATE
        );
        action_accelerators[slow_down_action] = "<Control>bracketleft";

        var speed_up_action = new SimpleAction (ACTION_SPEED_UP, null);
        speed_up_action.activate.connect (on_speed_up);
        state.bind_property (
            "can-speed-up",
            speed_up_action,
            "enabled",
            BindingFlags.SYNC_CREATE
        );
        action_accelerators[speed_up_action] = "<Control>bracketright";
    }

    private void register_actions () {
        var app = (Gtk.Application) GLib.Application.get_default ();
        foreach (var action in action_accelerators.get_keys ()) {
            add_action (action);
            var accels = action_accelerators[action].to_array ();
            app.set_accels_for_action (ACTION_PREFIX + action.name, accels);
        }
    }

    private void create_layout () {
        grid = new Gtk.Grid ();

        var header_bar = new Widgets.HeaderBar (state);
        grid.attach (header_bar, 0, 0);

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
            position = state.library_position
        };
        paned.bind_property (
            "position",
            state,
            "library_position",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL
        );

        var library = new Widgets.LibraryPane (state);
        paned.pack1 (library, false, true);
        var simulation = new Widgets.SimulationPane (state);
        paned.pack2 (simulation, true, false);
        grid.attach (paned, 0, 1);

        child = grid;
    }

    private void on_play_pause () {
        state.is_playing = !state.is_playing;
    }

    private void on_step_forward () {
        state.is_playing = false;
        state.step_by_one ();
    }

    private void on_slow_down () {
      state.simulation_speed -= State.SPEED_STEP;
    }

    private void on_speed_up () {
      state.simulation_speed += State.SPEED_STEP;
    }
}
