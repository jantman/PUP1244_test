# PUP1244_test

Tests for [PUP-1244](https://tickets.puppetlabs.com/browse/PUP-1244). I can't find a nice,
clean way to add this to the upstream acceptance tests, so some standalone tests for now.

To run the tests: ``bundle install --path vendor`` and then ``run.sh``; the latter
runs with BEAKER_destroy=no BEAKER_debug=on and redirects output to beaker.out
