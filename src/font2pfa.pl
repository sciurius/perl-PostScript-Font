#!/usr/local/bin/perl
my $RCS_Id = '$Id$ ';

# Author          : Johan Vromans
# Created On      : January 1999
# Last Modified By: Johan Vromans
# Last Modified On: Mon Feb  8 20:33:46 1999
# Update Count    : 22
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
my $type = $0 =~ /pfb$/ ? "pfb" : "pfa";
my ($debug, $trace) = (0, 0);
options ();

################ Presets ################

use PostScript::Font;

my $TMPDIR = $ENV{'TMPDIR'} || '/usr/tmp';

################ The Process ################

my $font = new PostScript::Font (shift(@ARGV),
				 error => 'die',
				 verbose => $verbose,
				 trace => $trace,
				 format => $type,
				);

if ( @ARGV ) {
    open (STDOUT, ">$ARGV[0]") || die ("$ARGV[0]: $!\n");
}
print STDOUT ($font->FontData);

################ Subroutines ################

sub options {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Process options.
    if ( @ARGV > 0 && $ARGV[0] =~ /^[-+]/ ) {
	usage ()
	    unless GetOptions (ident	=> \$ident,
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
    -ascii|pfa		decodes to .pfa format (default for pfb2pfa)
    -binary|pfb		encodes to .pfb format (default for pfa2pfb)
    -help		this message
    -ident		show identification
    -verbose		verbose information
EndOfUsage
    exit 1;
}

=pod

=head1 NAME

pfb2pfa - decodes binary or ASCII encoded PostScript fonts
pfa2pfb - encodes ASCII or binary encoded PostScript fonts

=head1 SYNOPSIS

  pfb2pfa [options] [input [output]]
  pfa2pfb [options] [input [output]]

    -ascii|pfa		decodes to .pfa (ASCII) format
    -binary|pfb		encodes to .pfb (binary) format
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
or B<-pfb> option is used, or the program is installed under a name
that ends in C<pfb>.

=head1 OPTIONS

=over 4

=item B<-ascii> or B<-pfa>

Output the font in ASCII (.pfa) format.
This is the default behavior when the program is installed under the
name C<pfb2pfa>.

=item B<-binary> or B<-pfb>

Output the font in binary (.pfb) format.
This is the default behavior when the program is installed under the
name C<pfa2pfb>.

=item B<-help>

Print a brief help message and exits.

=item B<-ident>

Prints program identification.

=item B<-verbose>

More verbose information.

=back

=head1 AUTHOR

Johan Vromans, Squirrel Consultancy <jvromans@squirrel.nl>

=head1 COPYRIGHT and DISCLAIMER

This program is Copyright 1990,1999 by Johan Vromans.
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

If you do not have a copy of the GNU General Public License write to
the Free Software Foundation, Inc., 675 Mass Ave, Cambridge,
MA 02139, USA.

=cut
