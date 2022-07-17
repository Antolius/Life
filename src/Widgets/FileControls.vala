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

        var menu_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8) {
            margin_left = 16,
            margin_right = 16,
            margin_top = 8,
            margin_bottom = 8
        };
        var open_button = create_open_button ();
        menu_box.pack_start (open_button);
        var save_button = create_save_button ();
        menu_box.pack_start (save_button);
        var save_as_button = create_save_as_button ();
        menu_box.pack_start (save_as_button);
        menu_box.show_all ();

        state.notify["saving-in-progress"].connect (() => {
            var sensitive = !state.saving_in_progress && !state.opening_in_progress;
            open_button.sensitive = sensitive;
            save_button.sensitive = sensitive;
            save_as_button.sensitive = sensitive;
        });
        state.notify["opening-in-progress"].connect (() => {
            var sensitive = !state.saving_in_progress && !state.opening_in_progress;
            open_button.sensitive = sensitive;
            save_button.sensitive = sensitive;
            save_as_button.sensitive = sensitive;
        });

        menu_popover = new Gtk.Popover (null) {
            child = menu_box
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

    private Gtk.Button create_open_button () {
        var btn = new Gtk.Button.from_icon_name (
            "document-open",
            Gtk.IconSize.LARGE_TOOLBAR
        ) {
            tooltip_text = _("Open a file")
        };

        btn.clicked.connect (on_open_button_clicked);
        return btn;
    }

    private void on_open_button_clicked () {
        menu_popover.popdown ();

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
                    _("No readable file was selected"),
                    Gtk.MessageType.WARNING,
                    _("Try opening another file"),
                    () => on_open_button_clicked ()
                ));
                return;
            }

            state.open.begin (path, (obj, res) => {
                var ok = state.open.end (res);
                if (!ok) {
                    state.info (new InfoModel (
                        _("Failed to open file"),
                        Gtk.MessageType.ERROR,
                        _("Try opening another file"),
                        () => on_open_button_clicked ()
                    ));
                }
            });
        }
    }

    private Gtk.Button create_save_button () {
        var btn = new Gtk.Button.from_icon_name (
            "document-save",
            Gtk.IconSize.LARGE_TOOLBAR
        ) {
            tooltip_text = _("Save this file")
        };

        btn.clicked.connect (on_save_button_clicked);
        return btn;
    }

    private void on_save_button_clicked () {
        menu_popover.popdown ();

        if (state.file != null) {
            state.save.begin (null, (obj, res) => {
                var ok = state.save.end (res);
                if (!ok) {
                    state.info (new InfoModel (
                        _("Failed to save current file"),
                        Gtk.MessageType.ERROR,
                        _("Try saving under a new name"),
                        () => on_save_as_button_clicked ()
                    ));
                }
            });
        } else {
            on_save_as_button_clicked ();
        }
    }

    private Gtk.Button create_save_as_button () {
        var btn = new Gtk.Button.from_icon_name (
            "document-save-as",
            Gtk.IconSize.LARGE_TOOLBAR
        ) {
            tooltip_text = _("Save this file with a different name")
        };

        btn.clicked.connect (on_save_as_button_clicked);
        return btn;
    }

    private void on_save_as_button_clicked () {
        menu_popover.popdown ();

        var dialog = new Gtk.FileChooserNative (
            null,
            null,
            Gtk.FileChooserAction.SAVE,
            null,
            null
        ) {
            filter = cells_filter ()
        };
        var filename = state.title + ".cells";
        if (state.file != null) {
            filename = "New " + filename;
        }
        dialog.set_current_name (filename);
        dialog.set_do_overwrite_confirmation (true);

        var res = dialog.run ();
        if (res == Gtk.ResponseType.ACCEPT) {
            var path = dialog.get_filename ();
            if (path == null) {
                state.info (new InfoModel (
                    _("No writeable file was selected"),
                    Gtk.MessageType.WARNING,
                    _("Try saving under a new name"),
                    () => on_save_as_button_clicked ()
                ));
                return;
            }

            state.save.begin (path, (obj, res) => {
                var ok = state.save.end (res);
                if (!ok) {
                    state.info (new Life.InfoModel (
                        _("Failed to save file"),
                        Gtk.MessageType.ERROR,
                        _("Try saving under a new name"),
                        () => on_save_as_button_clicked ()
                    ));
                }
            });
        }
    }

    private Gtk.FileFilter cells_filter () {
        var cells_filter = new Gtk.FileFilter ();
        cells_filter.set_filter_name (_("Cells files"));
        cells_filter.add_pattern ("*.cells");
        return cells_filter;
    }
}
