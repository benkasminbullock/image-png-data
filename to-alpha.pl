#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use lib "$Bin/lib";
use Image::PNG::Data 'gray2alpha';
my $infile = "$Bin/examples/gecko-1200-gray8.png";
gray2alpha ($infile);
