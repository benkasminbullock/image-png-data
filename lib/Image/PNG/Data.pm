package Image::PNG::Data;
use warnings;
use strict;
use Carp;
use utf8;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw//;
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
our $VERSION = '0.01';
require XSLoader;
XSLoader::load ('Image::PNG::Data', $VERSION);
1;
