#!/usr/local/bin/perl
my $RCS_Id = '$Id$ ';

# Author          : Johan Vromans
# Created On      : January 1999
# Last Modified By: Johan Vromans
# Last Modified On: Wed Jan  6 19:02:35 1999
# Update Count    : 10
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
my $verbose = 0;
my $type = "pfa";
my ($debug, $trace) = (0, 0);
&options;

################ Presets ################

use FindBin;
use lib $FindBin::Bin;
use PSFonts;

my $TMPDIR = $ENV{'TMPDIR'} || '/usr/tmp';

################ The Process ################

my $font = PostScript::Type1::loadfont (shift(@ARGV),
					error => 'die',
					check => 'relaxed',
					trace => $trace,
					format => $type,
				       );

if ( @ARGV ) {
    open (STDOUT, ">$ARGV[0]") || die ("$ARGV[0]: $!\n");
}
print STDOUT ($font);

################ Subroutines ################

sub options {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Process options.
    if ( @ARGV > 0 && $ARGV[0] =~ /^[-+]/ ) {
	&usage 
	    unless &GetOptions (ident	=> \$ident,
				verbose	=> \$verbose,
				"ascii|pfa"  => sub { $type = "pfa" },
				"binary|pfb" => sub { $type = "pfb" },
				"asm"	     => sub { $type = "asm" },
				trace	=> \$trace,
				help	=> \$help,
				debug	=> \$debug)
		&& !$help;
    }
    print STDERR ("This is $my_package [$my_name $my_version]\n")
	if $ident;
    usage () unless @ARGV <= 2;
}

sub usage {
    print STDERR <<EndOfUsage;
This is $my_package [$my_name $my_version]
Usage: $0 [options] [input [output]]
    -ascii|pfa		decodes to .pfa format
    -binary|pfb		encodes to .pfb format
    -help		this message
    -ident		show identification
    -verbose		verbose information
EndOfUsage
    exit 1;
}
=pod

=head1 NAME

pfb2pfa - decodes binary encoded PostScript fonts

=head1 SYNOPSIS

  pfb2pfa [options] [input [output]]

    -ascii|pfa		decodes to .pfa format
    -binary|pfb		encodes to .pfb format
    -help		this message
    -ident		show identification
    -verbose		verbose information

=head1 DESCRIPTION

B<pfb2pfa> converts a PostScript font.

The program takes, as command line arguments, the name of a PostScript
font file, encoded either in binary (.pfb) or ascii (.pfa) format,
optionally followed by the name of the output file. If no filenames
are supplied, the program reads from standard input and writes to
standard output.

The output will be ASCII encoded (.pfa format), unless the B<-binary>
or B<-pfb> option is used.

=head1 OPTIONS

=over 4

=item B<-ascii> or B<-pfa>

Output the font in ASCII (.pfa) format.

=item B<-binary> or B<-pfb>

Output the font in binary (.pfb) format.

=item B<-help>

Print a brief help message and exits.

=item B<-ident>

Prints program identification.

=item B<-verbose>

More verbose information.

=back

=cut
