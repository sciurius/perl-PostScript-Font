#!/usr/local/bin/perl
my $RCS_Id = '$Id$ ';

# Author          : Johan Vromans
# Created On      : Tue Sep 15 15:59:04 1992
# Last Modified By: Johan Vromans
# Last Modified On: Fri Jan 22 12:13:18 1999
# Update Count    : 134
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
my $include = 1;
my $verbose = 0;
my $title = "";
my ($debug, $trace, $test) = (0, 0, 0);
options ();

################ Presets ################

use FindBin;
use lib $FindBin::Bin;
use PostScript::Font;

my $TMPDIR = $ENV{'TMPDIR'} || '/usr/tmp';

################ The Process ################

my $samples = 999;
my $page = 0;
my $lastfam = '';
my $date = localtime(time);

my @needed = qw(Times-Roman);	# fonts %%Include-d
my @supplied = ();		# fonts %%Supplied

print STDERR ("Warning: no -title specified\n") if $title eq "";
$title = ps_str ($title);
preamble ();
my $file;

foreach $file ( @ARGV ) {

    my $font = new PostScript::Font ($file,
				     verbose => $verbose, trace => $trace,
				     error => 'warn');
    next unless defined $font;

    my $name = $font->name;
    my $fam = $font->family;
    unless ( $name ) {
	print STDERR ("$file: Missing /FontName\n");
	next;
    }

    if ( $samples >= 38 ) {
	print STDOUT ("showpage\n") if $page;
	$page++;
	print STDOUT ("%%Page: $page $page\n");
	print STDOUT ("($date) $title (Page $page) Header\n");
	$samples = 0;
    }
    if ( $samples == 0 ) {
	$lastfam = $fam;
    }
    elsif ( $fam ne $lastfam ) {
	$lastfam = $fam;
	if ( $lastfam and $page > 0 ) {
	    $samples++;
	}
    }

    print STDOUT ("save\n");
    if ( $include ) {
	print STDOUT ("%%BeginResource: font ", $font->name, "\n");
	print STDOUT ($font->data, "\n");
	print STDOUT ("%%EndResource\n");
	push (@supplied, $font->name);
    }
    else {
	print STDOUT ("%%IncludeResource: font ", $font->name, "\n");
	push (@needed, $font->name);
    }
    print STDOUT ("/$name ", 800-($samples*20), " Sample\n");
    print STDOUT ("restore\n");
    $samples++;
}

wrapup ();
exit 0;

################ Subroutines ################

sub preamble {
    while ( <DATA> ) {
	if ( $title ne "" && /^%%Title:/ ) {
	    $_ = '%%Title: ' . $title . "\n";
	}
	print STDOUT ($_);
    }
}

sub wrapup {
    print STDOUT ("showpage\n") if $samples;
    print STDOUT ("%%Trailer\n");
    fmtline ("%%DocumentNeededResources:", "font", @needed) if @needed;
    print STDOUT ("%%DocumentSuppliedResources: procset FontSampler 0 0\n");
    fmtline ("%%+", "font", @supplied) if @supplied;
    print STDOUT ("%%Pages: $page\n");
    print STDOUT ("%%EOF\n");
}

sub fmtline {
    my ($tag, $type, @list) = @_;
    my $line = "$tag $type";
    foreach ( @list ) {
	if ( length($line) + length($_) > 78 ) {
	    print STDOUT ($line, "\n");
	    $line = "%%+ $type";
	}
	$line .= " " . $_;
    }
    print STDOUT ($line, "\n");
}

sub ps_str ($) {
    # Form a string suitable for PostScript. Internal coding is ISO.

    my ($line) = @_;
    my $res = '';

    # Handle ISO chars and quotes.
    while ( $line =~ /^(.*?)([\200-\377"'()])(.*)$/s ) {      #'"]/{
	$res .= $1;		# `; # before
	my $chr = $2;		# the match
	$line = $3;		# '; # after

	# Quotes
	if ( $chr eq '"' ) {
	    $res .= ($res eq '' || $res =~ /\s$/) ? "\\204" : "\\202";
	}
	elsif ( $chr eq "'" ) {
	    if ( $line =~ /^(s-|s\s|t\s)/ ) { # 's-Gravenhage, 't, 's nachts
		$res .= "'";
	    }
	    else {
		$res .= ($res eq '' || $res =~ /\s$/) ? "`" : "'";
	    }
	}
	# Pseudo-quotes
	elsif ( $chr eq "\336" ) {
	    $res .= '\\207';
	}
	elsif ( $chr eq "\320" ) {
	    $res .= "\\206";
	}
	# Parenthesis and others
        elsif ( $chr eq '(' || $chr eq ')' || $chr eq '\\' ) {
	    $res .= '\\' . $chr;
	}
	# Normal ISO
	else {
	    $res .= sprintf("\\%03o", ord($chr));
	}
    }

    '(' . $res . $line . ')';      		   # return

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
				'title=s' => \$title,
				'trace' => \$trace,
				'help' => \$help,
				'debug' => \$debug)
		&& !$help;
    }
    print STDERR ("This is $my_package [$my_name $my_version]\n")
	if $ident;
}

sub usage {
    print STDERR <<EndOfUsage;
This is $my_package [$my_name $my_version]
Usage: $0 [options] [.pfa file ...]
    -title XXX		page title
    -[no]include	do [not] include font files
    -help		this message
    -ident		show identification
    -verbose		verbose information
EndOfUsage
    exit 1;
}
=pod

=head1 NAME

fontsampler - make sample pages from PostScript fonts

=head1 SYNOPSIS

fontsampler [options] [PostScript font files ...]

 Options:
   -title XXX		optional page title
   -[no]include         do [not] include font files
   -ident		show identification
   -help		brief help message
   -man                 full documentation
   -verbose		verbose information

=head1 DESCRIPTION

B<fontsampler> makes quick access sample pages of PostScript fonts by
printing the font name and a selection of characters. Each font gets
one line of information, allowing for some 30 or more font samples per
page.

The program takes, as command line arguments, a series of PostScript
font files. Each file should contain one ASCII encoded font (a so
called C<.pfa> file), or a binary encoded font (a so called C<.pfb>
file).

Each font is defined within its own environment, and flushed from
memory after it is used. This allows the results to be printed on most
PostScript printers.

The resultant PostScript document conforms to Adobe's Document
Structuring Conventions (DSC) version 3.0.

=head1 OPTIONS

=over 4

=item B<-include>

The font definitions are included in the resultant PostScript
document. This is enabled by default, and required for all fonts that
are not resident in your printer.

By disabling B<include> (with B<-noinclude>), no font data will be
included, and DSC comments are used to
notice the print manager to insert to font data when the job is
printed.

=item B<-title> I<XXX>

A descriptive title to be printed on every page.

=item B<-help>

Print a brief help message and exits.

=item B<-ident>

Prints program identification.

=item B<-verbose>

More verbose information.

=back

=head1 BUGS AND PROBLEMS


=cut
__END__
%!PS-Adobe-3.0
%%Creator: Johan Vromans <jvromans@squirrel.nl>
%%Title: (fonts)
%%Pages: (atend)
%%DocumentNeededResources: (atend)
%%DocumentSuppliedResources: (atend)
%%EndComments
%%BeginResource: procset FontSampler 0 0
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
  x  50 add y0 20 add moveto T setfont show
  x 500 add 20        moveto T setfont dup stringwidth pop neg 0 rmoveto show
} def
%%EndResource
%%EndProlog
%%IncludeResource: font Times-Roman
%%BeginSetup
/T /Times-Roman findfont 10 scalefont def
/Temp 64 string def
/x 50 def
/y0  800 def
%%EndSetup
