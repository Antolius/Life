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

public class Life.State : Object {

    private static int DEFAULT_SCALE = 10;          // 10px per board point
    private static int DEFAULT_PLAYBACK_SPEED = 10; // 10 generations per second

    public int scale { get; set; }                  // pix els per board point
    public int playback_speed { get; set; }         // generations per second
    public Tool active_tool { get; set; }

    public State () {
        Object (
            scale: DEFAULT_SCALE,
            playback_speed: 10,
            active_tool: Tool.PENCIL
        );
    }

    public enum Tool {
        POINTER,
        PENCIL,
        ERASER,
    }
}
