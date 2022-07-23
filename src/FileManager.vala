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

public class Life.FileManager : Object {

    public const string FILE_EXTENSION = ".cells";

    public Drawable drawable { get; construct; }
    public Editable editable { get; construct; }
    public File? open_file { get; set; }

    private uint? autosave_debounce_timer_id;
    private bool autosave_in_progress = false;

    public signal void pattern_opened (Pattern pattern);
    public signal void failed_to_open ();
    public signal void pattern_saved (Pattern pattern);
    public signal void failed_to_save ();

    public FileManager (Drawable drawable, Editable editable) {
        Object (
            drawable: drawable,
            editable: editable
        );
    }

    public bool autosave_exists () {
        var internal_autosave_file = internal_autosave_file ();
        return internal_autosave_file.query_exists ();
    }

    public async Pattern? open (string path) {
        var source_file = File.new_for_path (path);
        var pattern = yield read (source_file);
        if (pattern != null) {
            open_file = source_file;
            pattern_opened (pattern);
        } else {
            failed_to_open ();
        }
        return pattern;
    }

    public async Pattern? open_internal_autosave () {
        var internal_autosave_file = internal_autosave_file ();
        return yield read (internal_autosave_file);
    }

    public async Pattern? save (string? destination_path = null) {
        var destination_file = open_file;

        if (destination_path != null) {
            destination_file = File.new_for_path (destination_path);
        }

        if (destination_file == null) {
            warning ("Cannot save to null file");
            failed_to_save ();
            return null;
        }

        var pattern = yield write (destination_file);
        if (pattern != null) {
            open_file = destination_file;
            pattern_saved (pattern);
        } else {
            failed_to_save ();
        }

        return pattern;
    }

    public void autosave_with_debounce () {
        if (autosave_debounce_timer_id != null) {
            Source.remove (autosave_debounce_timer_id);
        }

        autosave_debounce_timer_id = Timeout.add (1000, () => {
            autosave_debounce_timer_id = null;
            if (!autosave_in_progress) {
                autosave_in_progress = true;
                do_autosave.begin ((obj, res) => {
                    do_autosave.end (res);
                    autosave_in_progress = false;
                });
            }

            return Source.REMOVE;
        });
    }

    private async void do_autosave () {
        if (open_file != null) {
            yield write (open_file);
            yield try_to_clean_up_autosave ();
        } else {
            var autosave_file = internal_autosave_file ();
            yield write (autosave_file);
        }
    }

    private async Pattern? read (File source_file) {
        try {
            var stream = yield source_file.read_async (Priority.LOW);
            var pattern = yield Pattern.from_plaintext (
                stream,
                file_name_without_extension (source_file)
            );

            editable.clear_all ();
            yield pattern.write_into_centered (editable, false);

            return pattern;
        } catch (Error err) {
            warning (
                "Failed to read pattern from file %s, %s",
                source_file.get_uri (),
                print_err (err)
            );
            return null;
        }
    }

    private async Pattern? write (File destination_file) {
        try {
            var shape = new CutoutShape.entire (drawable);
            var title = file_name_without_extension (destination_file);
            var pattern = Pattern.from_shape (title, shape);
            var stream = yield destination_file.replace_readwrite_async (
                null,
                false,
                FileCreateFlags.REPLACE_DESTINATION,
                Priority.LOW
            );
            yield pattern.write_as_plaintext (stream.output_stream);
            return pattern;
        } catch (Error err) {
            warning (
                "Failed to write pattern into file %s, %s",
                destination_file.get_uri (),
                print_err (err)
            );
            return null;
        }
    }

    private string file_name_without_extension (File file) {
        var filename = file.get_basename ();
        if (filename == null) {
            return Pattern.DEFAULT_NAME;
        }

        if (filename.has_suffix (FILE_EXTENSION)) {
            return filename[0: filename.length - FILE_EXTENSION.length];
        }

        return filename;
    }

    private async void try_to_clean_up_autosave () {
        var autosave_file = internal_autosave_file ();
        try {
            yield autosave_file.delete_async (Priority.LOW);
        } catch (Error err) {
            debug (
                "Failed to delete old autosave file %s, %s",
                autosave_file.get_uri (),
                print_err (err)
            );
        }
    }

    private File internal_autosave_file () {
        var data_dir = Environment.get_user_data_dir ();
        var path = data_dir + "/" + Pattern.DEFAULT_NAME + FILE_EXTENSION;
        return File.new_for_path (path);
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
