#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use FindBin '$Bin';
use Perl::Build;

my %build = (
    make_pod => "$Bin/make-pod.pl",
    pre => "/home/ben/projects/check4libpng/copy2inc.pl $Bin/inc",
);

if ($ENV{CI}) {
    delete $build{pre};
    $build{verbose} = 1;
    $build{no_make_examples} = 1;
}

perl_build (
    %build,
);
exit;
