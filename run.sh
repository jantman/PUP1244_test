#!/bin/bash

BEAKER_debug=on BEAKER_destroy=no bundle exec rake beaker 2>&1 | tee beaker.out
cat beaker.out | ./ansi2html.sh > beaker.out.html
