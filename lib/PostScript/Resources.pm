# RCS Status      : $Id$# Author          : Johan Vromans
# Created On      : December 1999
# Last Modified By: Johan Vromans
# Last Modified On: Wed May 12 18:53:19 1999
# Update Count    : 64
# Status          : Looks okay

################ Module Preamble ################

package PostScript::FontResource;

use strict;

BEGIN { require 5.005; }

use IO;

use vars qw($VERSION);
$VERSION = "1.0";

my $trace;
my $verbose;
my @sections;

sub new {
    my $class = shift;
    my $font = shift;
    my (%atts) = (error => 'die',
		  verbose => 0, trace => 0,
		  @_);
    my $self = { file => $font };
    bless $self, $class;

    $trace = lc($atts{trace});
    $verbose = $trace || lc($atts{verbose});

    eval {
	$self->_loadinfo;
    };

    if ( $@ ) {
	die ($@) unless lc($atts{error}) eq "warn";
	warn ($@);
	return undef;
    }

    $self;
}

sub _loadinfo ($) {

    my ($self) = shift;

    my $data;			# data

    eval {			# so we can use die

	my $fn = $self->{file};
	my $fh = new IO::File;	# font file
	my $sz = -s $fn;	# file size

	$fh->open ($fn) || die ("$fn: $!\n");
	print STDERR ("$fn: Loading Resources file\n") if $verbose;

	# Read in the data.
	my $line = <$fh>;
	die ("$fn: Unrecognized file format\n")
	  unless $line =~ /^PS-Resources-([\d.]+)/;

	@sections = ("Sections");
	while ( @sections ) {
	    my $section = shift (@sections);
	    my $loader = defined &{"_load$section"} ? "_load$section" :
	      "_skipSection";
	    no strict 'refs';
	    die ("$fn: Premature end of $section data\n")
	      if $fh->eof || !$loader->($self, $fh, $section);
	}
	$fh->close;
    };
    die ($@) if $@;
    $self;
}

sub _loadSections ($$$) {
    my ($self, $fh, $name) = @_;
    print STDERR ("$self->{file}: Loading section list $.\n") if $trace;
    while ( <$fh> ) {
	chomp;
	return 1 if $_ eq ".";
	push (@sections, $_);
    }
    return 0;
}

sub _loadFontAFM ($$$) {
    my ($self, $fh, $name) = @_;
    print STDERR ("$self->{file}: Loading section $name $.\n") if $trace;
    my $line = "";
    my %afm = ();
    $self->{FontAFM} = \%afm;
    while ( 1 ) {
	return 0 if $fh->eof;
	$line .= <$fh>;
	if ( $line =~ /^(.*)\\$/ ) {
	    $line = $1;
	    next;
	}
	else {
	    chomp ($line);
	}
	return 1 if $line =~ /^\.$/;
	# PostScriptName=the/file.afm
	$afm{$1} = $2 if $line =~ /^([^=]+)=(.*)$/;
	$line = "";
    }
    return 0;
}

sub _loadFontFamily ($$$) {
    my ($self, $fh, $name) = @_;
    print STDERR ("$self->{file}: Loading section $name $.\n") if $trace;
    my $line = "";
    my %fam = ();
    $self->{FontFamily} = \%fam;
    while ( 1 ) {
	return 0 if $fh->eof;
	$line .= <$fh>;
	if ( $line =~ /^(.*)\\$/ ) {
	    $line = $1;
	    next;
	}
	else {
	    chomp ($line);
	}
	return 1 if $line =~ /^\.$/;
	# Familiyname=Type1,PostScriptName1,Type2,PostScriptName2,...
	$fam{$1} = { split (',', $2) } if $line =~ /^([^=]+)=(.*)$/;
	$line = "";
    }
    return 0;
}

sub _loadFontOutline ($$$) {
    my ($self, $fh, $name) = @_;
    print STDERR ("$self->{file}: Loading section $name $.\n") if $trace;
    my $line = "";
    my %ol = ();
    $self->{FontOutline} = \%ol;
    while ( 1 ) {
	return 0 if $fh->eof;
	$line .= <$fh>;
	if ( $line =~ /^(.*)\\$/ ) {
	    $line = $1;
	    next;
	}
	else {
	    chomp ($line);
	}
	return 1 if $line =~ /^\.$/;
	# PostScriptName=the/file.pfa
	$ol{$1} = $2 if $line =~ /^([^=]+)=(.*)$/;
	$line = "";
    }
    return 0;
}

sub _skipSection ($$$) {
    my ($self, $fh, $name) = @_;
    print STDERR ("$self->{file}: Skipping section $name $.\n") if $trace;

    my $line = "";
    while ( 1 ) {
	return 0 if $fh->eof;
	$line .= <$fh>;
	if ( $line =~ /^(.*)\\$/ ) {
	    $line = $1;
	    next;
	}
	else {
	    chomp ($line);
	}
	return 1 if $line =~ /^\.$/;
	$line = "";
    }
    return 0;
}

1;

__END__

################ Documentation ################

=head1 NAME

PostScript::FontResource - module to fetch data from Unix PostScript Resource C<.upr> files

=head1 SYNOPSIS

  my $info = new PostScript::FontResource (filename, options);

=head1 OPTIONS

=over 4

=item error => [ 'die' | 'warn' ]

How errors must be handled.

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
