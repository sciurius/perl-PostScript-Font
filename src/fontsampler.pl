#!/usr/local/bin/perl
my $RCS_Id = '$Id$ ';

# Author          : Johan Vromans
# Created On      : Tue Sep 15 15:59:04 1992
# Last Modified By: Johan Vromans
# Last Modified On: Mon Dec 28 14:07:40 1998
# Update Count    : 101
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
my $title = "";
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

# Uncomment one of these lines for the .pfb to .pfa conversion.
#my $t1ascii = "t1ascii >/dev/null <";	# t1utils
my $t1ascii = "pfbtops ";		# groff
$title = ps_str ($title) if $title ne "";

foreach $file ( @ARGV ) {

    if ( $samples >= 38 ) {
	print ("showpage\n") if $page;
	$page++;
	print ("%%Page: $page $page\n");
	print ("($date) $title (Page $page) Header\n");
	$samples = 0;
    }

    my $fn = $file;
    if ( $file =~ /\.pfb$/i ) {
	unless ( $include ) {
	    warn ("$file: skipped (use -include)\n");
	    next;
	}
	$file = "$t1ascii$file|";
	print STDERR ("+ $file\n") if $trace;
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
				'load!' => \$load,
				'title=s' => \$title,
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
    -title XXX		optional page title
    -[no]include	do [not] include font files
    -[no]load		do [not] load the fonts from disk
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
   -[no]load            do [not] load the fonts from disk
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
file). The binary files are internally ASCIIfied by running the
B<pfbtops> program that comes with the GNU B<groff> package.

Each font is defined within its own environment, and flushed from
memory after it is used. This allows the results to be printed on most
PostScript printers.

=head1 OPTIONS

=over 4

=item B<-include>

The font definitions are included in the resultant PostScript
document. This is required for all fonts that are not resident in your
printer.

=item B<-load>

The font definitions are dynamically loaded when the resultant
PostScript document is processed. This only works if your PostScript
rendering engine runs on the local machine, and has access to the
files on disk (e.g. B<Ghostscript>, B<Ghostview>). To print the
document on a PostScript printer, use the B<-include> option.

=item B<-title> I<XXX>

Optional title to be printed on every page.

=item B<-help>

Print a brief help message and exits.

=item B<-ident>

Prints program identification.

=item B<-verbose>

More verbose information.

=back

=head1 BUGS AND PROBLEMS

The resultant PostScript document conforms to Adobe's DSC 2.0, but
only as far as I know.

The conversion program for binary encoded fonts is hard-wired to
B<pfbtops> and must be accessible through the normal search C<PATH>.
Alternatively, the B<t1ascii> program, part of the B<T1utils> package
can be used. See the source if B<fontsampler> for instructions.

=cut
__END__
%!PS-Adobe-2.0
%%Creator: Johan Vromans <jvromans@squirrel.nl>
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
  x  50 add y0 20 add moveto T setfont show
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
