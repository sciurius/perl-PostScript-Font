#!/usr/local/bin/perl
my $RCS_Id = '$Id$ ';

# Author          : Johan Vromans
# Created On      : Tue Sep 15 15:59:04 1992
# Last Modified By: Johan Vromans
# Last Modified On: Thu Dec 17 13:29:12 1998
# Update Count    : 78
# Status          : Unknown, Use with caution!

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
my $include = 0;
my $load = 0;
my $verbose = 0;
my ($debug, $trace, $test) = (0, 0, 0);
&options;

################ Presets ################

my $TMPDIR = $ENV{'TMPDIR'} || '/usr/tmp';

################ The Process ################

my $samples = 0;
my $page = 0;
my $lastfam = '';
my $date = localtime(time);
my @todo = ();

&preamble;
my $file;
foreach $file ( @ARGV ) {

    if ( $samples >= 38 ) {
	print ("showpage\n") if $page;
	$page++;
	print ("%%Page: $page $page\n");
	print ("($date) (Page $page) Header\n");
	$samples = 0;
    }

    my $fn = $file;
    if ( $file =~ /\.pfb$/i ) {
	unless ( $include ) {
	    warn ("$file: skipped (use -include)\n");
	    next;
	}
	$file = "t1ascii < $file 2>/dev/null |";
    }
    open (FONT, $file) || die ("$file: $!\n");
    my $name;
    my $fam;
    print "save\n";
    while ( <FONT> ) {
	print if $include;
	next if /^%/;
	if ( m|/FontName +/(\S+)| ) {
	    $name = $fam = $1;
	    $fam = $` if $fam =~ /-/;
	    $lastfam = $fam if $samples == 0;
	    last unless $include;
	}
    }
    close (FONT);

#    unless ( defined $name ) {
#	$name = $fn;
#	$name =~ s/\..+$//;
#	$name =~ m|([^/]+)$|;
#	$name = $fam = $1;
#	$fam = $` if $fam =~ /-/;
#	$lastfam = $fam if $samples == 0;
#	warn ("$file: Missing FontName, assuming $name\n");
#    }

    if ( defined $name ) {

	if ( $fam ne $lastfam ) {
	    $lastfam = $fam;
	    if ( $lastfam and $page > 0 ) {
		$samples++;
	    }
	}

	if ( $load ) {
	    print ("($file) run\n");
	}
	print ("/$name ", 800-($samples*20), " Sample\n");
	$samples++;
    }
    else {
	warn ("$fn: Missing FontName\n");
    }
    print ("restore\n");
}
&wrapup;
exit 0;

################ Subroutines ################

sub preamble {
    print while <DATA>;
    $page = 0;
    $samples = 999;
}

sub wrapup {
    print ("showpage\n") if $samples;
    print ("%%Pages: $page\n");
    print ("%%EOF\n");
}

sub options {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Process options.
    if ( @ARGV > 0 && $ARGV[0] =~ /^[-+]/ ) {
	&usage 
	    unless &GetOptions ('ident' => \$ident,
				'verbose' => \$verbose,
				'include!' => \$include,
				'load!' => \$load,
				'trace' => \$trace,
				'help' => \$help,
				'debug' => \$debug)
		&& !$help;
    }
    print STDERR ("This is $my_package [$my_name $my_version]\n")
	if $ident;
    $include = 0 if $load;
    $load = 0 if $include;
}

sub usage {
    print STDERR <<EndOfUsage;
This is $my_package [$my_name $my_version]
Usage: $0 [options] [.pfa file ...]
    -[no]include	do [not] include font files
    -[no]load		do [not] load the fonts from disk
    -help		this message
    -ident		show identification
    -verbose		verbose information
EndOfUsage
    exit 1;
}
__END__
%!PS-Adobe-2.0
%%Creator:Johan Vromans
%%Title: (fonts)
%%Pages: (atend)
%%DocumentSuppliedProcSets: procs 0 0
%%DocumentFonts: Times-Roman
%%EndComments
%%BeginProcSet: procs 0 0
/Sample {
  /y exch def
  dup /FName exch def
  findfont 14 scalefont /F14 exch def
  x y moveto
  T setfont FName Temp cvs show
  x 160 add y moveto
  F14 setfont (ABCDEFGHIJKL abcdefghijklm 0123456789) show
} def
/Header {
  x 500 add y0 20 add moveto T setfont dup stringwidth pop neg 0 rmoveto show
  x 500 add 20        moveto T setfont dup stringwidth pop neg 0 rmoveto show
} def
%%EndProcSet
%%EndProlog
%%BeginSetup
/T /Times-Roman findfont 10 scalefont def
/Temp 64 string def
/x 50 def
/y0  800 def
%%EndSetup
