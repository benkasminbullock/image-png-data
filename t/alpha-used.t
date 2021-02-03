use FindBin '$Bin';
use lib "$Bin";
use IPNGDT;

my @filex = (
    ['luv.png', 1],
    ['blue.png', 0],
);

for (@filex) {
    cmp_ok (
	alpha_used (
	    read_png_file ("$Bin/$_->[0]")
	), '==', $_->[1],
	"Got expected $_->[1] for $_->[0]"
    );
}
done_testing ();
