use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Image/PNG/Data.pm';
my $pod = 'lib/Image/PNG/Data.pod';
my $github = 'github.com/benkasminbullock/image-png-data';
my $repo = "https://$github";
WriteMakefile (
    NAME => 'Image::PNG::Data',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
    },
    META_MERGE => {
	'meta-spec' => {
	    version => 2,
	},
        resources => {
            repository => {
		type => 'git',
		url => "git://$github.git",
		web => $repo,
	    },
            bugtracker => {
		web => "$repo/issues",
	    },
	    no_index => {
#		directory => ['tmpl', 'build', 'inc'],
		file => ['t/IPNGDT.pm'],
	    },

#	    homepage => 'http://',
        },
	
    },
    MIN_PERL_VERSION => '5.006001',
    OBJECT => 'Data.o',
);
