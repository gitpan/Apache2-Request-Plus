#!/usr/bin/perl -w
use strict;
use lib '../../';
use Apache2::Request::Plus;
use Test;

# Not really sure what to test: it just outputs stuff.  This script
# just tests that the module loads.

BEGIN { plan tests => 1 };

print "yup, it loads\n";

ok(1);
