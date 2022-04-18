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

namespace Life.HashLife.Cache.LfuCacheTests {

    public void add_funcs () {
        Test.add_func ("/HashLife/LFU/test_cache", test_cache);
        Test.add_func (
            "/HashLife/LFU/test_cache_with_random_data",
            test_cache_with_random_data
        );
    }

    void test_cache () {
        var value_provider_invocation_cont = 0;
        var cache = new LfuCache<int, string> (
            2,
            (key) => {
                value_provider_invocation_cont++;
                return "%d".printf (key);
            }
        );

        assert (cache.access (1) == "1");
        assert (value_provider_invocation_cont == 1);
        assert (cache.size == 1);

        assert (cache.access (1) == "1");
        assert (value_provider_invocation_cont == 1);
        assert (cache.size == 1);

        assert (cache.access (1) == "1");
        assert (value_provider_invocation_cont == 1);
        assert (cache.size == 1);

        assert (cache.access (2) == "2");
        assert (value_provider_invocation_cont == 2);
        assert (cache.size == 2);

        assert (cache.access (2) == "2");
        assert (value_provider_invocation_cont == 2);
        assert (cache.size == 2);

        assert (cache.access (3) == "3");
        assert (value_provider_invocation_cont == 3);
        assert (cache.size == 2);

        assert (cache.access (2) == "2");
        assert (value_provider_invocation_cont == 4);
        assert (cache.size == 2);

        assert (cache.access (1) == "1");
        assert (value_provider_invocation_cont == 4);
        assert (cache.size == 2);
    }

    void test_cache_with_random_data () {
        var cache = new LfuCache<int32, string> (
            10,
            (key) => "%d".printf (key)
        );

        for (int i = 0; i < 100000; i++) {
            var key = Random.int_range (0, 15);
            assert (cache.access (key) == key.to_string ());
            assert (cache.size <= 10);
        }
    }
}
