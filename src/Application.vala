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

public class Life.Application : Gtk.Application {

    public static Settings settings;

    public Application () {
        Object (
            application_id: Constants.PROJECT_NAME,
            flags: ApplicationFlags.HANDLES_OPEN
        );
    }

    public static new Application get_default() {
        return (Application) GLib.Application.get_default ();
    }

    static construct {
        settings = new Settings (Constants.PROJECT_NAME);
    }

    protected override void activate () {
        unowned var existing_windows = get_windows ();
        if (existing_windows.length () > 0) {
            var window = existing_windows.first ().data as MainWindow;
            window.present ();
        } else {
            var window = create_new_window (null);
            window.show ();
        }
    }

    protected override void open (File[] files, string hint) {
        foreach (var file in files) {
            State state;
            var window = create_new_window (out state);
            window.show ();
            state.open.begin (file.get_path ());
        }
    }

    private MainWindow create_new_window (out State? state) {
        var factory = new HashLife.QuadFactory ();
        var tree = new HashLife.QuadTree (8, factory);
        var simulation = new HashLife.Simulation (tree, factory);
        var parallel_stepper = new HashLife.ParallelStepper (simulation);
        var file_manager = new FileManager (tree, tree);
        var gsettings_manager = new GSettingsManager (settings);

        shutdown.connect (() => {
            parallel_stepper.shutdown_gracefully ();
            gsettings_manager.shutdown_gracefully ();
        });

        state = new State (
            tree,
            tree,
            parallel_stepper,
            file_manager,
            gsettings_manager
        );

        return new MainWindow (state, this);
    }

    public override void startup () {
        base.startup ();
        Hdy.init ();
        Gtk.IconTheme.get_default ()
            .add_resource_path ("/hr/from/josipantolis/life");
        foce_elementary_style ();
        link_dark_mode_settings ();
    }

    private void foce_elementary_style () {
        var settings = Gtk.Settings.get_default ();
        if (!settings.gtk_theme_name.has_prefix ("io.elementary.stylesheet")) {
            settings.gtk_theme_name = "io.elementary.stylesheet.blueberry";
        }

        if (settings.gtk_icon_theme_name != "elementary") {
            settings.gtk_icon_theme_name = "elementary";
        }
    }

    private void link_dark_mode_settings () {
        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        var dark_mode = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        gtk_settings.gtk_application_prefer_dark_theme = dark_mode;

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            var dm = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
            gtk_settings.gtk_application_prefer_dark_theme = dm;
        });
    }
}
