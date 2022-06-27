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

public class Life.Widgets.TutorialBoard : DrawingBoard {

    private Pattern pattern;
    private string[,] text_overlay;

    public TutorialBoard (
        Scaleable scaleable,
        Pattern pattern
    ) {
        base (scaleable, pattern);
        this.pattern = pattern;
        this.text_overlay = {{}};
    }

    public TutorialBoard.with_text_overlay (
        Scaleable scaleable,
        Pattern pattern,
        string[,] text_overlay
    ) {
        base (scaleable, pattern);
        this.pattern = pattern;
        this.text_overlay = text_overlay;
    }

    protected override void apply_highlights (Cairo.Context ctx) {
        var ltc = color_palette.dead_cell_color;
        var dtc = color_palette.live_cell_color;

        for (var i = 0; i < text_overlay.length[0]; i++) {
            for (var j = 0; j < text_overlay.length[1]; j++) {
                var x = (j + 0.45) * scaleable.scale;
                var y = (i + 0.6) * scaleable.scale;
                ctx.move_to (x, y);

                if (pattern.data[i][j]) {
                    ctx.set_source_rgba (ltc.red, ltc.green, ltc.blue, 1);
                } else {
                    ctx.set_source_rgba (dtc.red, dtc.green, dtc.blue, 1);
                }

                ctx.show_text (text_overlay[i, j]);
            }
        }
    }

}
