#!/usr/local/bin/perl
my $RCS_Id = '$Id$ ';

# Author          : Johan Vromans
# Created On      : Tue Sep 15 15:59:04 1992
# Last Modified By: Johan Vromans
# Last Modified On: Thu Dec 17 09:01:45 1998
# Update Count    : 41
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

&preamble0;
while ( <> ) {
    print if $include;
    next if /^%/;
    push (@todo, [ $ARGV, $1 ]) if m|/FontName +/(\S+)|;
    # &add_sample ($ARGV, $1) if m|/FontName +/(\S+)|;
}
&preamble1;
my $todo;
foreach $todo ( @todo ) {
    add_sample (@$todo);
}
&wrapup;
exit 0;

################ Subroutines ################

sub preamble0 {
    while ( <DATA> ) {
	print;
	last if /^%%EndProcSet/;
    }
}

sub preamble1 {
    print while <DATA>;
    $page = 0;
    $samples = 999;
}

sub add_sample {
    my $file = shift;
    my $name = shift;
    my $fam = $name;
    $fam = $` if $fam =~ /-/;
    if ( $fam ne $lastfam ) {
	$lastfam = $fam;
	if ( $lastfam and $page > 0 ) {
	    print ("Space\n");
	    $samples++;
	}
    }

    if ( $samples >= 38 ) {
	print ("Eject\n") if $page;
	$page++;
	print ("%%Page: $page $page\n");
	print ("($date) (Page $page) Header\n");
	$samples = 0;
	$lastfam = $fam;
    }
    print ("($file) run\n") if $load && !$include;
    print ("/$name Sample\n");
    $samples++;
}

sub wrapup {
    print ("Eject\n") if $samples;
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
  /FName exch def	% font name
  /F FName findfont def
  /F14 F 14 scalefont def
  x y moveto
  T setfont FName Temp cvs show
  x 150 add y moveto
  F14 setfont (ABCDEFGHIJKL abcdefghijklm 0123456789) show
  /y y 20 sub def
} def
/Space {
  /y y 20 sub def
} def
/Eject {
  showpage
  /y y0 def
} def
/Header {
  exch pop x 450 add y 20 add moveto T setfont show
} def
%%EndProcSet
%%EndProlog
%%BeginSetup
/T /Times-Roman findfont 10 scalefont def
/Temp 64 string def
/x 50 def
/y0  800 def
/y y0 def
%%EndSetup
