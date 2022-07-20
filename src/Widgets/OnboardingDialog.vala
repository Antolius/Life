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

public class Life.Widgets.OnboardingDialog : Granite.Dialog {

    private static Scaleable scale = new ConstantScale () {
        board_scale = State.DEFAULT_SCALE * 4
    };

    private static ushort[,] glider_gen_1_data = {
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0},
        {0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    };

    private static ushort[,] glider_gen_2_data = {
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    };

    private static ushort[,] glider_gen_3_data = {
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0},
        {0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    };

    private static string[,] top_cells_neighbors = {
        {" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " "},
        {" ", " ", " ", " ", "↘️", "⬇️", "↙️", " ", " ", " ", " "},
        {" ", " ", " ", " ", "➡️", " ", "⬅️", " ", " ", " ", " "},
        {" ", " ", " ", " ", "↗️", "⬆️", "↖️", " ", " ", " ", " "},
        {" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " "},
        {" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " "},
        {" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " "}
    };

    private static string[,] glider_neighbour_counts = {
        {"0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0"},
        {"0", "0", "0", "0", "1", "1", "1", "0", "0", "0", "0"},
        {"0", "0", "0", "0", "1", "1", "2", "1", "0", "0", "0"},
        {"0", "0", "0", "1", "3", "5", "3", "2", "0", "0", "0"},
        {"0", "0", "0", "1", "1", "3", "2", "2", "0", "0", "0"},
        {"0", "0", "0", "1", "2", "3", "2", "1", "0", "0", "0"},
        {"0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0"}
    };

    private static string[,] glider_neighbour_counts_with_checkboxes = {
        {"0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0"},
        {"0", "0", "0", "0", "1", "1", "1", "0", "0", "0", "0"},
        {"0", "0", "0", "0", "1", "1✖️", "2", "1", "0", "0", "0"},
        {"0", "0", "0", "1", "3✔️", "5", "3✔️", "2", "0", "0", "0"},
        {"0", "0", "0", "1", "1✖️", "3✔️", "2✔️", "2", "0", "0", "0"},
        {"0", "0", "0", "1", "2", "3✔️", "2", "1", "0", "0", "0"},
        {"0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0"}
    };

    private Hdy.Carousel carousel;

    construct {
        var content = new Gtk.Grid () {
            row_spacing = 24,
            hexpand = true,
            vexpand = true
        };

        var title = new Granite.HeaderLabel (_("Conway's Game of Life Primer")) {
            halign = Gtk.Align.CENTER
        };
        content.attach (title, 0, 0);

        carousel = new Hdy.Carousel () {
            valign = Gtk.Align.CENTER
        };
        carousel.add (build_intro_slide ());
        carousel.add (build_neighbors_slide ());
        carousel.add (build_counts_slide ());
        carousel.add (build_rules_slide ());
        carousel.add (build_second_generation_slide ());
        carousel.add (build_third_generation_slide ());
        carousel.add (build_patterns_slide ());
        content.attach (carousel, 0, 1);

        var navigator = build_navigator_buttons (carousel);
        content.attach (navigator, 0, 2);
        content.show_all ();

        get_content_area ().add (content);
    }

    private Gtk.Widget build_intro_slide () {
        var txt = """In Conway's Game of Life the world is represented by an infinite 2 dimensional grid. Each square in the grid, i.e. a cell, can be either dead or alive. The initial pattern of cells evolves from one generation into the next according to a set of rules. You can define the initial pattern and then observe its evolution."""; // vala-lint=line-length
        return build_slide (txt, glider_gen_1_data);
    }

    private Gtk.Widget build_neighbors_slide () {
        var txt = """Here are the rules for evolving a pattern into the next generation.

First, note that each cell borders 8 other cells. They are called neighbors.""";
        return build_slide (txt, glider_gen_1_data, top_cells_neighbors);
    }

    private Gtk.Widget build_counts_slide () {
        var txt = """To determine if a cell will be alive or dead in the next generation its live neighbors are counted. This count ranges from 0 (when cell has no live neighbors) to 8 (when all its neighbors are alive)."""; // vala-lint=line-length
        return build_slide (txt, glider_gen_1_data, glider_neighbour_counts);
    }

    private Gtk.Widget build_rules_slide () {
        var txt = """In the next generation:

1. A live cell with fewer than 2 live neighbors will die.
2. A live cell with either 2 or 3 live neighbors will live on.
3. A live cell with more than 3 live neighbors will die.
4. A dead cell with exactly 3 live neighbors will become alive."""; // vala-lint=line-length
        return build_slide (
            txt,
            glider_gen_1_data,
            glider_neighbour_counts_with_checkboxes
        );
    }

    private Gtk.Widget build_second_generation_slide () {
        var txt = """These rules are applied over and over again to progress through generations. Depending on the initial pattern interesting behaviors emerge.

Can you predict what the next generation of this pattern will look like?"""; // vala-lint=line-length
        return build_slide (txt, glider_gen_2_data);
    }

    private Gtk.Widget build_third_generation_slide () {
        var txt = """Notice that this third generation looks like the original pattern. In fact, in two more steps it will flip again and appear as if the original pattern moved one cell down and to the right. That's why this pattern is called Glider."""; // vala-lint=line-length
        return build_slide (txt, glider_gen_3_data);
    }

    private Gtk.Widget build_patterns_slide () {
        var txt = """This is one example of a complex behavior resulting from simple rules of the Game of Life. There are other patterns which move like this one. There are those which oscillate between several states. There are those which forever remain the same. And there are many which behave erratically or completely die out.

Try finding some interesting patterns by yourself, or explore the included Patterns Library for inspiration."""; // vala-lint=line-length
        return build_slide (txt, glider_gen_3_data);
    }

    private Gtk.Grid build_slide (
        string text,
        ushort[,] pattern_data,
        string[,]? text_overlay_data = null
    ) {
        var slide = new Gtk.Grid () {
            row_spacing = 12,
            margin_left = 16,
            margin_right = 16
        };

        var explanation = new Gtk.Label (text) {
            selectable = true,
            justify = Gtk.Justification.FILL,
            max_width_chars = 60,
            wrap = true,
            wrap_mode = Pango.WrapMode.WORD_CHAR
        };
        slide.attach (explanation, 0, 0);

        var shape = new Shape.from_data (pattern_data);
        var pattern = Pattern.from_shape ("Pattern", shape);
        var board = text_overlay_data != null
            ? new TutorialBoard.with_text_overlay (scale, pattern, text_overlay_data)
            : new TutorialBoard (scale, pattern);
        var board_frame = new Gtk.Frame (null) {
            child = board,
            valign = Gtk.Align.END
        };
        slide.attach (board_frame, 0, 1);

        return slide;
    }

    private Gtk.Widget build_navigator_buttons (Hdy.Carousel carousel) {
        var prev_btn = new Gtk.Button.with_label ("Previous") {
            sensitive = false,
            halign = Gtk.Align.START,
            hexpand = false
        };
        prev_btn.clicked.connect (() => {
            var slies = carousel.get_children ();
            var idx = carousel.get_position ();
            if (idx > 0) {
                carousel.scroll_to (slies.nth_data ((uint) idx - 1));
            }
        });

        var next_btn = new Gtk.Button.with_label ("Next") {
            halign = Gtk.Align.END,
            hexpand = false
        };
        next_btn.clicked.connect (() => {
            var slies = carousel.get_children ();
            var idx = carousel.get_position ();
            if (idx < slies.length () - 1) {
                carousel.scroll_to (slies.nth_data ((uint) idx + 1));
            } else {
                response (0);
            }
        });

        carousel.page_changed.connect ((idx) => {
            if (idx == 0) {
                prev_btn.sensitive = false;
            } else {
                prev_btn.sensitive = true;
            }

            var suggested_class = Gtk.STYLE_CLASS_SUGGESTED_ACTION;
            if (idx == carousel.n_pages - 1) {
                next_btn.label = "Start exploring";
                next_btn.get_style_context ().add_class (suggested_class);
            } else {
                next_btn.label = "Next";
                next_btn.get_style_context ().remove_class (suggested_class);
            }
        });

        var buttons_row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            valign = Gtk.Align.END,
            homogeneous = true,
            margin_left = 16,
            margin_right = 16
        };
        buttons_row.get_style_context ().add_class ("dialog-action-area");
        buttons_row.pack_start (prev_btn);
        buttons_row.set_center_widget (new Hdy.CarouselIndicatorDots () {
            carousel = carousel
        });
        buttons_row.pack_end (next_btn);
        return buttons_row;
    }

}
