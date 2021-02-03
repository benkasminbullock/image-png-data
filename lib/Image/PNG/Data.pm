package Image::PNG::Data;
use warnings;
use strict;
use Carp;
use utf8;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/
    any2gray8
    bwpng
    rgb2gray
    rmalpha
/;
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
our $VERSION = '0.00_01';
require XSLoader;
XSLoader::load ('Image::PNG::Data', $VERSION);

use Image::PNG::Libpng ':all';
use Image::PNG::Const ':all';


# White background for either RGB or grayscale.

my %white = (red => 0xff, green => 0xff, blue => 0xff, gray => 0xff);

sub any2gray8
{
    my ($file, %options) = @_;
    my $reader = create_reader ($file);
    $reader->set_verbosity (1);
    $reader->read_info ();
    my $ihdr = $reader->get_IHDR ();
    my $bd = $ihdr->{bit_depth};
    my $ct = $ihdr->{color_type};
    if ($bd != 8) {
	if ($bd == 16) {
	    $reader->set_scale_16 ();
	}
	elsif ($bd < 8) {
	    # There is no GRAY_ALPHA with less than 8 bits, so don't
	    # worry about that.
	    if ($ct == PNG_COLOR_TYPE_GRAY) {
		$reader->set_expand_gray_1_2_4_to_8 ();
	    }
	    elsif ($ct == PNG_COLOR_TYPE_PALETTE) {
		$reader->set_palette_to_rgb ();
		$reader->set_rgb_to_gray ();
	    }
	    else {
		croak "Unknown color type $ct and bit-depth $bd combination in $file";
	    }
	}
	else {
	    croak "Unknown bit depth $bd in $file";
	}
    }
    if ($ct & PNG_COLOR_MASK_ALPHA) {
	# We need to add a background color.
	my $bkgd = $reader->get_bKGD ();
	if ($bkgd) {
	    $reader->set_background ($bkgd, PNG_BACKGROUND_GAMMA_SCREEN, 1);
	}
	elsif ($options{bkgd}) {
	    $reader->set_background ($bkgd, PNG_BACKGROUND_GAMMA_SCREEN, 1);
	}
	else {
	    $reader->set_background (\%white, PNG_BACKGROUND_GAMMA_SCREEN, 1);
	}
    }
    if ($ct & PNG_COLOR_MASK_COLOR) {
	$reader->set_rgb_to_gray ();
    }
    elsif ($ct == PNG_COLOR_TYPE_PALETTE) {
	$reader->set_palette_to_rgb ();
	$reader->set_rgb_to_gray ();
    }
    $reader->read_image ();
    $reader->read_end ();
    my $rows = $reader->get_rows ();
    my $wpng = create_write_struct ();
    my %ihdr = (
	height => $ihdr->{height},
	width => $ihdr->{width},
	color_type => PNG_COLOR_TYPE_GRAY,
	bit_depth => 8,
	interlace_type => $ihdr->{interlace_type},
    );
    $wpng->set_IHDR (\%ihdr);
    $wpng->set_rows ($rows);
    return $wpng;
}

sub bwpng
{

}

sub css2color
{

}

sub color2css
{

}

# Private

sub open_png
{
    my ($me, $file, $verbose) = @_;
    my $rpng;
    if (-f $file) {
	if ($verbose) {
	    vmsg ("opening '$file'");
	}
	$rpng = create_reader ($file);
	if (! $rpng) {
	    carp "$me: Image::PNG::Libpng::create_reader('$file') failed";
	    return undef;
	}
	return $rpng;
    }
    if (ref $file eq 'Image::PNG::Libpng') {
	if ($verbose) {
	    vmsg ("reading from an existing object");
	}
	return $file;
    }
    carp "$me: first argument not a file or an Image::PNG::Libpng object";
    return undef;
}

# Chunks which are only useful for RGB

my @rgbchunks = qw!cHRM iCCP!;

# Public

sub rgb2gray
{
    my $me = 'rgb2gray';
    my ($file, %options) = @_;
    my $verbose = $options{verbose};
    if ($verbose) {
	vmsg ("messages are on");
    }
    my $rpng = open_png ($me, $file, $verbose);
    if ($verbose) {
	vmsg ("reading color type");
    }
    $rpng->read_info ();
    my $ihdr = $rpng->get_IHDR ();
    my $ct = $ihdr->{color_type};
    if (! ($ct & PNG_COLOR_MASK_COLOR)) {
	carp "$me: '$file' does not contain RGB colors";
	return undef;
    }
    if ($verbose) {
	vmsg ("input color type is " . color_type_name ($ct));
    }
    if ($verbose) {
	vmsg ("reading image data");
    }
    $rpng->set_rgb_to_gray ();
    $rpng->read_image ();
    $rpng->read_end ();
    if ($options{grayonly}) {
	my $was_colorful = $rpng->get_rgb_to_gray_status ();
	if ($was_colorful) {
	    carp ("$me: option 'grayonly' but '$file' was RGB");
	    return undef;
	}
    }
    my $wpng = copy_png ($rpng);
    $ihdr->{color_type} = $ct & ~PNG_COLOR_MASK_COLOR;
    if ($verbose) {
	vmsg ("output color type is " . color_type_name ($ihdr->{color_type}));
    }
    $wpng->set_IHDR ($ihdr);
    if ($verbose) {
	vmsg ("finished creating PNG for writing");
    }
    return $wpng;
}

my $slowpoke = 0;

# Private

sub alpha_used
{
    my ($png, $rows) = @_;
    my $rowbytes = $png->get_rowbytes ();
    my $ihdr = $png->get_IHDR ();
    my $bit_depth = $ihdr->{bit_depth};
    my $channels = color_type_channels ($ihdr->{color_type});
    if ($bit_depth != 8) {
	croak "Module doesn't handle bit depth of 16";
    }
    if ($slowpoke) {
	my $n = $rowbytes / $channels;
	my $b = 'C' x $n;
	croak "$rowbytes is not a multiple of $channels" unless $n == int ($n);
	for my $row (@$rows) {
	    for my $i (0..$n-1) {
		my $pixel = substr ($row, $i * $channels, $channels);
		my @bytes = unpack ($b, $pixel);
		#print "@bytes\n";
		my $alpha = $bytes[-1];
		if ($alpha != 255) {
		    # Sorry, Donny Osmond, one bad apple DOES spoil the
		    # whole bunch.
		    return 1;
		}
	    }
	}
	return 0;
    }
    else {
	my $split = split_alpha ($png);
	my $alpha = $split->{alpha};
	if ($alpha =~ /[^\xFF]/) {
	    #print "alpha channel not all opaque.\n";
	    return 1;
	}
	return 0;
    }
}

# Public

sub rmalpha
{
    my $me = 'rmalpha';
    my ($file, %options) = @_;
    my $verbose = $options{verbose};
    if ($verbose) {
	vmsg ("messages are on");
    }
    my $rpng = open_png ($me, $file, $verbose);
    $rpng->read_info ();
    my $ihdr = $rpng->get_IHDR ();
    my $ct = $ihdr->{color_type};
    if (! ($ct & PNG_COLOR_MASK_ALPHA)) {
	carp "image does not contain an alpha channel";
	return undef;
    }
    $rpng->read_image ();
    my $rows = $rpng->get_rows ();
    my $alpha_used = alpha_used ($rpng, $rows);
    if (! $alpha_used) {
	if ($verbose) {
	    vmsg ("alpha channel is present but unused");
	}
	if ($verbose) {
	    vmsg ("re-reading $file");
	}
	$rpng = open_png ($me, $file, $verbose);
	$rpng->read_info ();
	$rpng->set_strip_alpha ();
	$rpng->read_image ();
	$rpng->read_end ();
	return copy_png ($rpng);
    }
    if ($options{unusedonly}) {
	carp "not all the pixels in '$file' are opaque";
	return undef;
    }
}

sub vmsg
{
    my ($msg) = @_;
    my @caller = caller (0);
    my (undef, $file, $line) = @caller;
    print "$file:$line: $msg\n";
}



1;
