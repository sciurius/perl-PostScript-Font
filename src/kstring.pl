#!/usr/local/bin/perl
my $RCS_Id = '$Id$ ';

# Author          : Johan Vromans
# Created On      : Fri Apr  9 14:51:00 2004
# Last Modified By: Johan Vromans
# Last Modified On: Sat Mar 12 16:18:45 2005
# Update Count    : 76
# Status          : Released

################ Common stuff ################

# $LIBDIR = $ENV{'LIBDIR'} || '/usr/local/lib/sample';
# unshift (@INC, $LIBDIR);
# require 'common.pl';
use strict;
my $my_package = 'Sciurix';
my ($my_name, $my_version) = $RCS_Id =~ /: (.+).pl,v ([\d.]+)/;
$my_version .= '*' if length('$Locker$ ') > 12;

################ Program parameters ################

use Getopt::Long 2.00;

my ($debug, $trace, $verbose) = (0, 0, 0);

################ Presets ################

use PostScript::Font;
use PostScript::FontMetrics;
use Carp;
use constant FONTSCALE => 1000;

################ The Process ################

my $f;
my $fm;
my $preamble = 0;
my $include = 0;
my $size = -1;
my $font = "";
my $x = 50;
my $y = 600;
my $text = "";
my $o_size = $size;
my $o_font = $font;
my $o_x = -1;
my $o_y = -1;

options ();
flush();

sub set_font {
    flush();
    $font = $_[1];
    my $metrics;
    ($font, $metrics) = ($1,$2) if $font =~ /^([^:]+):([^:]+)$/;
    $f = new PostScript::Font($font);
    if ( $f->FontType eq '1' ) {
	unless ( defined($metrics) ) {
	    $metrics = $font;
	    $metrics =~ s/\.[^.]+$//;
	    $metrics .= ".afm";
	}
	$fm = new PostScript::FontMetrics($metrics, verbose => 1);
    }
    else {
	$fm = do {
	    local($^W) = 0;
	    no warnings;
	    new PostScript::FontMetrics($font, verbose => 1);
	};
    }
}

sub set_size {
    flush();
    $size = undef;
    my $arg = $_[1];
    ($size) = $arg =~ /^(\d+(?:\.\d*)?)$/;
    die("Invalid size: $arg\n") unless defined($size);
}

sub set_origin {
    flush();
    $x = undef;
    $y = undef;
    my $arg = $_[1];
    ($x,$y) = $arg =~ /^(-?\d+(?:\.\d*)?),(-?\d+(?:\.\d*)?)$/;
    die("Invalid origin: $arg\n")
      unless defined($x) && defined($y);
}

sub set_text {
    $text .= " " if $text ne "";
    $text .= shift;
}

sub flush {
    print STDOUT
      ("% TJ operator to print typesetinfo vectors.\n",
       "/TJ {\n",
       "  { dup type /stringtype eq { show } { 0 rmoveto } ifelse }\n",
       "  forall\n",
       "} bind def\n",
      ) if $preamble;
    $preamble = 0;

    return if $text eq "";

    print STDOUT
      ("% Font $fm->{file}\n",
       $include && ($o_font ne $font) ? ${$f->{data}} : "",
       "/", $f->FontName, " findfont $size scalefont setfont\n")
	if $o_font ne $font || $o_size != $size;
    $o_font = $font;
    $o_size = $size;

    print STDOUT
      ("$x $y moveto\n")
	if $o_x != $x || $o_y != $y;
    $o_x = $x;
    $o_y = $y;

    my $k = $fm->kstring($text);
    print ps_tj($k);
    $text = "";
}

################ Subroutines ################

=head2 ps_tj

Example:

    print $ts->ps_tj ($tj);

Produces the PostScript code to print the text at the current position.
The argument to this function must be the result of a call to C<tjvector>.

=cut

# Print a typesetting vector. Use TJ definition.
sub ps_tj {
    local ($_);

    my ($t) = @_;
    my $ret = '';
    croak ("ps_tj: Font size not set") unless $size;
    my $scale = $size/FONTSCALE;
    $ret .= "[";
    my $l = 1;
    foreach ( @$t ) {
	unless ( /^\(/ ) {
	    $_ = sprintf("%.4f", $_*$scale);
	    s/0+$//;
	}
	if ( ($l += 1 + length) >= 80 ) {
	    $ret .= "\n ";
	    $l = 2 + length;
	}
	$ret .= " " . $_;
    }
    $ret .= " ] TJ\n";
    $ret;
}

################ Command Line Options ################

sub options {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Process options.
    if ( @ARGV > 0 && $ARGV[0] =~ /^[-+]/ ) {
	usage ()
	    unless GetOptions (ident	=> \$ident,
			       include  => \$include,
			       'font=s' => \&set_font,
			       'size=f' => \&set_size,
			       'origin=s' => \&set_origin,
			       '<>'	=> \&set_text,
			       ps	=> \$preamble,
			       verbose	=> \$verbose,
			       trace	=> \$trace,
			       help	=> \$help,
			       debug	=> \$debug)
	      && !$help;
    }

    print STDERR ("This is $my_package [$my_name $my_version]\n")
	if $ident;
}

sub usage {
    print STDERR <<EndOfUsage;
This is $my_package [$my_name $my_version]
Usage: $0 [ options ] { -font XXX -size NN -origin XX,YY text text ... } ...

Where XXX is the name of a PostScript Type 1 or a TrueType font.
For Type 1 fonts, the metrics will be the fontname with .afm extension,
unless it is explicitly specified with "-font XXX:YYY".

Other options:
    -preamble           write the postscript definitions as well
    -include		include the font data as well
    -help		this message
    -ident		show identification
    -verbose		verbose information
EndOfUsage
    exit 1;
}
