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

public class Life.Widgets.LibraryPane : Gtk.ScrolledWindow {

    public State state { get; construct; }
    private Gtk.Box content;

    public LibraryPane (State state) {
        Object (
            state: state
        );
    }

    construct {
        get_style_context ().add_class ("library");

        content = new Gtk.Box (Gtk.Orientation.VERTICAL, 16) {
            margin_top = 16,
            vexpand = true,
            valign = Gtk.Align.FILL
        };
        var title = new Gtk.Label (_("Patterns Library"));
        title.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        content.pack_start (title, false, false);

        var attribution = new Granite.HyperTextView () {
            wrap_mode = Gtk.WrapMode.WORD,
            valign = Gtk.Align.END,
            margin = 8
        };
        attribution.buffer.text = _("Content of the Patterns Library is adapted from LifeWiki, awailable on https://conwaylife.com/wiki");
        content.pack_end (attribution, true);

        child = content;

        load_library.begin ();
    }

    private async void load_library () {
        var patterns = new Gee.ArrayList<Pattern> ();

        try {
            var no_flags = ResourceLookupFlags.NONE;
            var patterns_path = "/" + Constants.resource_base () + "/patterns";
            var files = resources_enumerate_children (patterns_path, no_flags);

            foreach (var file_name in files) {
                var path = patterns_path + "/" + file_name;
                var input = resources_open_stream (path, no_flags);
                var pattern = yield Pattern.from_plaintext (input);
                patterns.add (pattern);
            }
        } catch (Error err) {
            warning (
                "Failed to load patterns library from resource file, %s",
                print_err (err)
            );
            Idle.add (load_library.callback);
            yield;
            state.info (new Life.InfoModel (
                _("Failed to load the patterns library"),
                Gtk.MessageType.ERROR,
                _("Retry loading"),
                () => load_library.begin ()
            ));
        }

        if (!patterns.is_empty) {
            create_library_sections (patterns);
        }
    }

    private void create_library_sections (Gee.List<Pattern> patterns) {
        string[] ordered_sections = {
            "Still life", "Oscillator", "Constellation", "Spaceship", "Puffer", "Methuselah", "Gun"
        };

        var titles = section_titles ();
        var descriptions = section_descriptions ();
        var grouped_patterns = group_patterns_by_type (patterns);

        foreach (var section in ordered_sections) {
            var section_widget = create_library_section (
                titles[section],
                descriptions[section],
                grouped_patterns[section]
            );

            content.pack_start (section_widget, false, false);
        }

        content.show_all ();
    }

    public Gee.Map<string, string> section_titles () {
        var titles = new Gee.HashMap<string, string> ();
        titles["Still life"] = "Still life";
        titles["Oscillator"] = "Oscillators";
        titles["Constellation"] = "Constelations";
        titles["Spaceship"] = "Spaceships";
        titles["Puffer"] = "Puffers";
        titles["Methuselah"] = "Methuselah";
        titles["Gun"] = "Guns";
        return titles;
    }

    public Gee.Map<string, string> section_descriptions () {
        var descriptions = new Gee.HashMap<string, string> ();
        descriptions["Still life"] = "Patterns that do not change from one generation to the next."; // vala-lint=line-length
        descriptions["Oscillator"] = "Patterns that repeat themselves after a fixed number of generations."; // vala-lint=line-length
        descriptions["Constellation"] = "Complex patterns comprised only of simple objects such as still lifes and oscillators."; // vala-lint=line-length
        descriptions["Spaceship"] = "Patterns that return to their initial state after a number of generations but in a different location."; // vala-lint=line-length
        descriptions["Puffer"] = "Paterns that move like spaceships, except that they leave debris behind."; // vala-lint=line-length
        descriptions["Methuselah"] = "Patterns that take many generations to stabilize and grow considerably in that time."; // vala-lint=line-length
        descriptions["Gun"] = "Stationary patterns that repeatedly emit spaceships forever."; // vala-lint=line-length
        return descriptions;
    }

    private Gee.Map<string, Gee.List<Pattern>> group_patterns_by_type (
        Gee.List<Pattern> all_patterns
    ) {
        all_patterns.sort ((p1, p2) => {
            var a1 = p1.width_points * p1.height_points;
            var a2 = p2.width_points * p2.height_points;
            return (int) (a1 - a2);
        });

        var groups = new Gee.HashMap<string, Gee.List<Pattern>> ();

        foreach (var pattern in all_patterns) {
            var group = groups[pattern.pattern_type];
            if (group == null) {
                group = new Gee.ArrayList<Pattern> ();
                groups[pattern.pattern_type] = group;
            }
            group.add (pattern);
        }

        return groups;
    }

    private Gtk.Expander create_library_section (
        string section_title,
        string section_description,
        Gee.List<Pattern> patterns
    ) {
        var list_box = new Gtk.ListBox () {
            selection_mode = Gtk.SelectionMode.NONE,
            hexpand = true
        };
        var patterns_store = new ListStore (typeof (Pattern));
        list_box.bind_model (patterns_store, create_row);

        foreach (var pattern in patterns) {
            patterns_store.append (pattern);
        }

        var title = new Gtk.Label (section_title) {
            tooltip_text = section_description,
            margin_start = 8
        };
        title.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        var expander = new Gtk.Expander (null) {
            child = list_box,
            label_widget = title,
            margin_start = 8
        };

        state.notify["library-animation-in-progress"].connect (() => {
            expander.expanded = false;
        });

        return expander;
    }

    private Gtk.ListBoxRow create_row (Object element) {
        var pattern = (Pattern) element;
        return new PatternLibraryRow (pattern, state);
    }

    private string print_err (Error err) {
        var format = "Error Message: \"%s\", Error code: %d, Error domain: %";
        format += uint32.FORMAT;
        return (format).printf (
            err.message,
            err.code,
            err.domain
        );
    }
}
