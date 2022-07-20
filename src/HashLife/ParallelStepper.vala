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

public class Life.HashLife.ParallelStepper : Object, Stepper {


    private Stepper _delegate;
    private ThreadPool<Stepper>? thread_pool;

    public ParallelStepper (Stepper delegate_stepper) {
        _delegate = delegate_stepper;
        _delegate.step_completed.connect (emit_step_completed_on_main_loop);

        try {
            thread_pool = new ThreadPool<Stepper>.with_owned_data (
                (stepper) => stepper.step (),
                1,
                true
            );
        } catch (ThreadError err) {
            warning ("Failed to initialize parallel stepper's thread pool, " +
                "will perform all step operations in the caller thread. " +
                "Underlaying error: %s", err.message
            );
        }
    }

    public int64 generation {
        get { return _delegate.generation; }
        set { _delegate.generation = value; }
    }

    public void step () {
        if (thread_pool != null) {
            try {
                thread_pool.add (_delegate);
                return;
            } catch (ThreadError err) {
                warning ("Failed to run step inside parallel stepper's " +
                    "thread pool, will perform this step operations in the " +
                    " caller thread. Underlaying error: %s", err.message
                );
            }
        }

        _delegate.step ();
    }

    public Stats.Metric[] stats () {
        return _delegate.stats ();
    }
    
    public void shutdown_gracefully () {
        ThreadPool.free ((owned) thread_pool, false, true);
    }

    private async void emit_step_completed_on_main_loop () {
        Idle.add (emit_step_completed_on_main_loop.callback);
        yield;
        step_completed ();
    }
}
