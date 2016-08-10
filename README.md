# PUP1244_test

[![Project Status: Abandoned – Initial development has started, but there has not yet been a stable, usable release; the project has been abandoned and the author(s) do not intend on continuing development.](http://www.repostatus.org/badges/latest/abandoned.svg)](http://www.repostatus.org/#abandoned)

Tests for [PUP-1244](https://tickets.puppetlabs.com/browse/PUP-1244). I can't find a nice,
clean way to add this to the upstream acceptance tests, so some standalone tests for now.

To run the tests: ``bundle install --path vendor`` and then ``run.sh``; the latter
runs with ``BEAKER_destroy=no BEAKER_debug=on``, redirects output to ``beaker.out``, and
html-izes the console output (redirected to ``beaker.out.html``, viewable using
[htmlpreview.github.com](http://htmlpreview.github.io/?https://github.com/jantman/PUP1244_test/blob/master/beaker.out.html)).
