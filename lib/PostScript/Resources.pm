# RCS Status      : $Id$# Author          : Johan Vromans
# Created On      : December 1999
# Last Modified By: Johan Vromans
# Last Modified On: Thu May 13 18:49:53 1999
# Update Count    : 120
# Status          : Looks okay

################ Module Preamble ################

package PostScript::Resources;

use strict;

BEGIN { require 5.005; }

use IO;
use File::Basename;
use File::Spec;

use vars qw($VERSION);
$VERSION = "1.0";

my $trace;
my $verbose;
my $error;

my @sections;

sub new {
    my $class = shift;
    my $upr = shift;
    my (%atts) = (error => 'die',	# 'die', 'warn' or 'ignore'
		  strategy => 'memory',	# 'memory' or 'demand'
		  verbose => 0,
		  trace => 0,
		  @_);
    my $self = { file => $upr };
    bless $self, $class;

    $trace = lc($atts{trace});
    $verbose = $trace || lc($atts{verbose});
    $error = lc($atts{error});
    $self->{prefix} = dirname ($upr);

    eval { $self->_loadInfo };
    if ( $@ ) {
	die ($@)  unless $error eq "warn";
	warn ($@) unless $error eq "ignore";
	return undef;
    }

    $self;
}

sub FontAFM ($$) {
    my ($self, $font) = @_;
    return undef unless defined ($font = $self->{FontAFM}->{$font});
    _buildfilename ($self->{prefix}, $font);
}

sub FontOutline ($$) {
    my ($self, $font) = @_;
    return undef unless defined ($font = $self->{FontOutline}->{$font});
    _buildfilename ($self->{prefix}, $font);
}

sub _loadInfo ($) {

    my ($self) = shift;

    my $data;			# data

    eval {			# so we can use die

	my $fn = $self->{file};
	my $fh = new IO::File;	# font file
	my $sz = -s $fn;	# file size

	$fh->open ($fn) || die ("$fn: $!\n");
	print STDERR ($fn, ": Loading Resources file\n") if $verbose;

	# Read in the data.
	my $line = <$fh>;
	die ($fn."[$.]: Unrecognized file format\n")
	  unless $line =~ /^PS-Resources-(Exclusive-)?([\d.]+)/;
	my $exclusive = defined $1;
	my $version = $2;

	# The resources file is organised in sections, each starting
	# with the section name and terminated by a line with just
	# a period.
	# Following the first PS-Resources line, the sections are
	# enumerated, e.g.:
	#
	#  PS-Resources-1.0
	#  FontAFM
	#  FontOutlines
	#  FontFamily
	#  FontPrebuilt
	#  FontBDF
	#  FontBDFSizes
	#  .
	#
	# Optionally, the name of the resource directory follows. It
	# is preceded with a slash, e.g.:
	#
	#  //usr/share/psresources
	#
	# This is then followed by each of the sections, e.g.:
	#
	#  FontAFM
	#  ... afm info ...
	#  .
	#  FontOutlines
	#  ... outlines info ...
	#  .
	#  FontFamily
	#  ... family info ...
	#  .
	#
	# Backslash escapes are NOT handled, except for continuation.
	#
	# We have a _loadXXX subroutine for each section, where XXX is
	# the section name. Flexible and extensible.
	#
	# The current approach is to ignore the first section.

	$self->_skipSection ($fh);

	# Then, load the sections from the file, skipping unknown ones.

	my $section;
	my $checkdir = 1;
	while ( defined ($section = _readLine ($self, $fh)) ) {
	    chomp ($section);
	    if ( $checkdir && $section =~ /^\/(.*)/ ) {
		$self->{prefix} = $1;
		$checkdir = 0;
		next;
	    }
	    $checkdir = 0;
	    my $loader = defined &{"_load$section"} ? "_load$section" :
	      "_skipSection";
	    no strict 'refs';
	    die ($fn."[$.]: Premature end of $section section\n")
	      if $fh->eof || !$loader->($self, $fh, $section);
	}
	$fh->close;

    };
    die ($@) if $@;
    $self;
}

sub _readLine ($$) {
    # Read a line, handling continuation lines.
    my ($self, $fh) = @_;
    my $line;
    while ( 1 ) {
	return undef if $fh->eof;
	$line .= <$fh>;
	if ( $line =~ /^(.*)\\$/ ) {
	    $line = $1;
	    redo;
	}
	$line = $1 if $line =~ /^(.*)%/; # remove comments
	$line =~ s/\s+$//;		# remove trailing blanks
	next unless $line =~ /\S/;	# skip empty lines
	return $line;
    }
    continue { $line = "" }
    undef;
}

sub _loadFontAFM ($$$) {
    my ($self, $fh, $name) = @_;
    print STDERR ($self->{file}, "[$.]: Loading section $name\n")
      if $trace;

    my %afm = ();
    $self->{FontAFM} = \%afm;

    my $line;
    while ( defined ($line = _readLine ($self, $fh)) ) {
	return 1 if $line =~ /^\.$/;

	# PostScriptName=the/file.afm
	if ( $line =~ /^([^=]+)=(.*)$/ ) {
	    $afm{$1} = $2;
	    next;
	}
	warn ($self->{file}, "[$.]: Invalid FontAFM entry\n")
	  unless $error eq "ignore";
    }
    return 1;
}

sub _loadFontFamily ($$$) {
    my ($self, $fh, $name) = @_;
    print STDERR ($self->{file}, "[$.]: Loading section $name\n")
      if $trace;

    my %fam = ();
    $self->{FontFamily} = \%fam;

    my $line;
    while ( defined ($line = _readLine ($self, $fh)) ) {
	return 1 if $line =~ /^\.$/;

	# Familiyname=Type1,PostScriptName1,Type2,PostScriptName2,...
	if ( $line =~ /^([^=]+)==?(.*)$/ ) {
	    $fam{$1} = { split (',', $2) };
	    next;
	}
	warn ($self->{file}, "[$.]: Invalid FontFamily entry\n")
	  unless $error eq "ignore";
    }
    return 1;
}

sub _loadFontOutline ($$$) {
    my ($self, $fh, $name) = @_;
    print STDERR ($self->{file}, "[$.]: Loading section $name\n")
      if $trace;

    my %pfa = ();
    $self->{FontOutline} = \%pfa;

    my $line;
    while ( defined ($line = _readLine ($self, $fh)) ) {
	return 1 if $line =~ /^\.$/;

	# PostScriptName=the/file.pfa
	if ( $line =~ /^([^=]+)=(.*)$/ ) {
	    $pfa{$1} = $2;
	    next;
	}
	warn ($self->{file}, "[$.]: Invalid FontOutline entry\n")
	  unless $error eq "ignore";
    }
    return 1;
}

sub _skipSection ($$$) {
    my ($self, $fh, $name) = (@_, 'list');
    print STDERR ($self->{file}, "[$.]: Skipping section $name\n")
      if $trace;

    my $line;
    while ( defined ($line = _readLine ($self, $fh)) ) {
	return 1 if $line =~ /^\.$/;
    }
    return 1;
}

sub _buildfilename ($$) {
    my ($prefix, $name) = @_;
    return $1 if $name =~ /^=(.*)$/;
    return $name if File::Spec->file_name_is_absolute ($name);
    File::Spec->canonpath (File::Spec->catfile ($prefix, $name));
}

sub 

1;

__END__

################ Documentation ################

=head1 NAME

PostScript::FontResource - module to fetch data from Unix PostScript Resource C<.upr> files

=head1 SYNOPSIS

  my $rsc = new PostScript::FontResources (filename, options);
  print STDOUT $rsc->FontAFM ("Times-Roman"), "\n";

=head1 OPTIONS

=over 4

=item error => [ 'die' | 'warn' | 'ignore' ]

How errors must be handled.

Invalid entries in the file are always reported unless the error
handling strategy is set to 'ignore'.

=item strategy => [ 'memory' | 'demand' ]

Strategy 'memory' causes all info to be loaded in memory structures.
This is suitable for small files or if several lookups are done on the
same file.

Strategy 'demand' costs less memory, but requires the file to be
re-parsed for every lookup request. This is suitable for large files
with few lookups.

Currently, only the 'memory' strategy is implemented.

=item verbose => I<value>

Prints verbose info if I<value> is true.

=item trace => I<value>

Prints tracing info if I<value> is true.

=back

=head1 DESCRIPTION

This package allows Unix font resource files, so called C<.upr> files,
to be read and parsed.

=head1 CONSTRUCTOR

=over 4

=item new ( FILENAME )

The constructor will read the file and parse its contents.

=back

=head1 INSTANCE METHODS

Each of these methods can return C<undef> if the corresponding
information could not be found in the file.

=over 4

=item FontAFM ( FONTNAME )

The name of the Adobe Font Metrics (.afm) file for the named font.

=item FontOutline ( FONTNAME )

The name of the PostScript Font program for the named font.

=back

=head1 KNOWN BUGS AND LIMITATIONS

Only FontAFM and FontOutline resources are implemented.

Backslash escape processing is not yet implemented, except for the
handling of line continuation.

This module is intended to be used on Unix systems only.
Your mileage on other platforms may vary.

=head1 AUTHOR

Johan Vromans, Squirrel Consultancy <jvromans@squirrel.nl>

=head1 COPYRIGHT and DISCLAIMER

This program is Copyright 1993,1999 by Squirrel Consultancy. All
rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either: a) the GNU General Public License as
published by the Free Software Foundation; either version 1, or (at
your option) any later version, or b) the "Artistic License" which
comes with Perl.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See either the
GNU General Public License or the Artistic License for more details.

=cut
