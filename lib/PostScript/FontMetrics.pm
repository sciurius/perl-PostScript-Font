# RCS Status      : $Id$
# Author          : Johan Vromans
# Created On      : December 1999
# Last Modified By: Johan Vromans
# Last Modified On: Fri Jan 15 15:36:52 1999
# Update Count    : 96
# Status          : Released

################ Copyright ################

# This program is Copyright 1990,1998 by Johan Vromans.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# If you do not have a copy of the GNU General Public License write to
# the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, 
# MA 02139, USA.

################ Module Preamble ################

package PostScript;

use strict;
use IO;

BEGIN {
    require 5.005;
    use Exporter ();
    use vars     qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = "0.01";
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    %EXPORT_TAGS = qw();
    @EXPORT_OK   = qw();
}

my $trace;

sub loadfont ($@) {

    my ($fn) = shift;
    my (%atts) = (error => 'die',
		  format => 'ascii', trace => 0, @_);
    $trace = lc($atts{trace});
    $atts{format} = "ascii" if lc($atts{format}) eq "pfa";
    $atts{format} = "binary" if lc($atts{format}) eq "pfb";

    my $data;			# font data
    my $name;			# font name
    my $type;			# font type
    my $fam;			# font family
    my $version;		# font version

    eval {			# so we can use die

	my $fh = new IO::File;	# font file
	my $sz = -s $fn;	# file size

	$fh->open ($fn) || die ("$fn: $!\n");

	# Read in the font data.
	my $len = 0;
	while ( $fh->sysread ($data, 32768, $len) > 0 ) {
	    $len = length ($data);
	}
	$fh->close;
	print STDERR ("Read $len bytes from $fn\n") if $trace;
	die ("$fn: Expecting $sz bytes, got $len bytes\n") unless $sz == $len;

	# Convert .pfb encoded font data.
	if ( $data =~ /^\200[\001-\003]/ ) {
	    $data = ${_pfb2pfa($fn,\$data)};
	}
	# Otherwise, must be straight PostScript.
	elsif ( $data !~ /^%!/ ) {
	    die ("$fn: Not a recognizable font file\n");
	}

	# Normalise line endings.
	$data =~ s/\015\012?/\n/g;

    };

    if ( $@ ) {
	die ($@) unless lc($atts{error}) eq "warn";
	warn ($@);
	return undef;
    }

    if ( wantarray ) {
	if ( $data =~ /^%!FontType(\d+)\n\/(\S+)\n/ ) {
	    $type = $1;
	    $name = $2;
	}
	elsif ( $data =~ /\/FontName\s*\/(\S+)/ ) {
	    $name = $1;
	}
	elsif ( $data =~ /\/FontName\s*\(([^\051]+)\)/ ) {
	    $name = $1;
	}
	if ( $data =~ /\/FamilyName\s*\/(\S+)/ ) {
	    $fam = $1;
	}
	elsif ( $data =~ /\/FamilyName\s*\(([^\051]+)\)/ ) {
	    $fam = $1;
	}
	unless ( defined $type ) {
	    $type = $1 if $data =~ /\/FontType\s+(\d+)/;
	}
	$version = $1 if $data =~ /\/version\s*\(([^\051]+)\)/;
	print STDERR ("=> Name = $name, type = $type\n") if $trace;
    }

    # Return new data.
    if ( lc($atts{format}) eq "asm" ) {
	$data = ${_pfa2asm($fn, \$data)};
    }
    elsif ( lc($atts{format}) eq "binary" ) {
	$data = ${_pfa2pfb($fn, \$data)};
    }
    wantarray ? ( font => $data, name => $name, family => $fam,
		  version => $version, type => $type ) : $data;
}

sub loadafm ($@) {

    my ($fn) = shift;
    my (%atts) = (error => 'die', trace => 0, @_);
    $trace = lc($atts{trace});

    my $name;			# font name
    my $type;			# font type
    my $fam;			# font family
    my $version;		# font version
    my $data;			# afm data

    eval {			# so we can use die

	my $fh = new IO::File;	# font file
	my $sz = -s $fn;	# file size

	$fh->open ($fn) || die ("$fn: $!\n");

	# Read in the afm data.
	my $len = 0;
	while ( $fh->sysread ($data, 32768, $len) > 0 ) {
	    $len = length ($data);
	}
	$fh->close;
	print STDERR ("Read $len bytes from $fn\n") if $trace;
	die ("$fn: Expecting $sz bytes, got $len bytes\n") unless $sz == $len;

	# Normalise line endings.
	$data =~ s/\015\012?/\n/g;

	if ( $data !~ /^StartFontMetrics/ || $data !~ /EndFontMetrics$/ ) {
	    die ("$fn: Not a recognizable AFM file\n");
	}

    };

    if ( $@ ) {
	die ($@) unless lc($atts{error}) eq "warn";
	warn ($@);
	return undef;
    }

    if ( wantarray ) {
	$name    = $1 if $data =~ /^FontName\s+(\S+)$/mi;
	$fam     = $1 if $data =~ /^FamilyName\s+(.+)$/mi;
	$version = $1 if $data =~ /^Version\s+(.+)$/mi;
	return ( afm => $data, name => $name, family => $fam, 
		 version => $version );
    }

    $data;
}

sub _pfb2pfa ($\$) {
    my ($fn, $data) = @_;	# NOTE: data is a ref!
    my $newdata = "";		# NOTE: will return a ref

    # Structure of .pfb font data:
    #
    #	( ASCII-segment | Binary-segment )+ EOF-indicator
    #
    #	ASCII-segment: \200 \001 length data
    #	Binary-sement: \200 \002 length data
    #	EOF-indicator: \200 \003
    #
    #	length is a 4-byte little endian 'long'.
    #	data   are length bytes of data.

    my $bin = "";		# accumulated unprocessed binary segments
    my $addbin = sub {		# binary segment processor
	print STDERR ("Processing binary segment, ",
		      length($bin), " bytes\n") if $trace;
	($bin = uc (unpack ("H*", $bin))) =~ s/(.{64})/$1\n/g;
	$newdata .= $bin;
	$newdata .= "\n" unless $newdata =~ /\n$/;
	$bin = "";
    };

    while ( length($$data) > 0 ) {
	my ($type, $info, $seg);

	last if $$data =~ /^\200\003/; # EOF indicator

	# Get font segment.
	die ("$fn: Invalid font segment format\n")
	  unless ($type, $info) = $$data =~ /^\200([\001-\002])(....)/s;

	my $len = unpack ("V", $info);
	# Can't use next statement since $len may be > 32766.
	# ($seg, $$data) = $$data =~ /^......(.{$len})(.*)/s;
	$seg = substr ($$data, 6, $len);
	$$data = substr ($$data, $len+6);

	if ( ord($type) == 1 ) {	# ASCII segment
	    $addbin->() if $bin ne "";
	    print STDERR ("ASCII segment, $len bytes\n") if $trace;
	    $newdata .= $seg;
	}
	else { # ord($type) == 2	# Binary segment
	    print STDERR ("Binary segment, $len bytes\n") if $trace;
	    $bin .= $seg;
	}
    }
    $addbin->() if $bin ne "";
    return \$newdata;
}

sub _pfa2pfb ($\$) {
    my ($fn, $data) = @_;	# NOTE: data is a ref!

    return "\200\001".pack("V",length($data)).$data."\200\003"
      unless $$data =~ m{(^.*\beexec\s*\n+)
                         ([A-Fa-f0-9\n]+)
                         (\s*cleartomark.*$)}sx;

    my ($pre, $bin, $post) = ($1, $2, $3);
    $bin =~ tr/A-Fa-f0-9//cd;
    $bin = pack ("H*", $bin);
    my $nulls;
    ($bin, $nulls) = $bin =~ /(.*[^\0])(\0+)?$/s;
    $nulls = defined $nulls ? length($nulls) : 0;
    while ( $nulls > 0 ) {
	$post = ("00" x ($nulls > 32 ? 32 : $nulls)) . "\n" . $post;
	$nulls -= 32;
    }

    my $newdata = 
      "\200\001".pack("V",length($pre)).$pre.
      "\200\002".pack("V",length($bin)).$bin.
      "\200\001".pack("V",length($post)).$post.
      "\200\003";

    return \$newdata;
}

sub _pfa2asm ($\$) {
    my ($fn, $data) = @_;	# NOTE: data is a ref!

    return $data
      unless $$data =~ m{(^.*\beexec\s*\n+)
                         ([A-Fa-f0-9\n]+)
                         (\n\s*cleartomark.*$)}sx;

    my ($pre, $bin, $post) = ($1, $2, $3);
    $bin =~ tr/A-Fa-f0-9//cd;
    $bin = pack ("H*", $bin);
    my $nulls;
    ($bin, $nulls) = $bin =~ /(.*[^\0])(\0+)?$/s;
    $nulls = defined $nulls ? length($nulls) : 0;
    while ( $nulls > 0 ) {
	$post = ("00" x ($nulls > 32 ? 32 : $nulls)) . "\n" . $post;
	$nulls -= 32;
    }

    my $newdata = "";

    # Conversion based on an C-program marked as follows:
    # /* Written by Carsten Wiethoff 1989 */
    # /* You may do what you want with this code, 
    #    as long as this notice stays in it */

    my $input;
    my $output;
    my $ignore = 4;
    my $buffer = 0xd971;

    while ( length($bin) > 0 ) {
	($input, $bin) = $bin =~ /^(.)(.*)$/s;
	$input = ord ($input);
	$output = $input ^ ($buffer >> 8);
	$buffer = (($input + $buffer) * 0xce6d + 0x58bf) & 0xffff;
	next if $ignore-- > 0;
	$newdata .= pack ("C", $output);
    }

    # End conversion.

    # Cleanup (for display only).
    $newdata =~ s/ \-\| (.+?) (\|-?)\n/" -| ".unpack("H*",$1)." $2\n"/ges;

    # Concatenate and return.
    $newdata = $pre . $newdata . $post;
    return \$newdata;
}

1;

__END__

my @opc12 = ("dotsection", "vstem3", "hstem3", undef, undef,	# 0-4
	     undef, "seac", "sbw", undef, undef,		# 5-9
	     undef, undef, "div", undef, undef,			# 10-14
	     undef, "callothersubr", "pop", undef, undef,	# 15-19
	     undef, undef, undef, undef, undef,			# 20-24
	     undef, undef, undef, undef, undef,			# 25-29
	     undef, undef, undef, "setcurrentpoint",		# 30-33
	    );

my @opc00 = ( undef, "hstem", undef, "vstem", "vmoveto",	# 0-4
	      "rlineto", "hlineto", "vlineto", "rrcurveto", "closepath", # 5-9
	      "callsubr", "return", \@opc12, "hsbw", "endchar",	# 10-14
	      undef, undef, undef, undef, undef,		# 15-19
	      undef, "rmoveto", "hmoveto", undef, undef,	# 20-24
	      undef, undef, undef, undef, undef,		# 25-29
	      "vhcurveto", "hvcurveto",				# 30-31
	   );


sub main::xxx () {

    my ($val, $b, $c);
    my $newdata = "";

    my $bin = "\xec\x6d\x72\x2c\x9d\x75\x06\xa7\x28\xbc\x70\xb3\x7b\x27\xf7";
    while ( length ($bin) > 0 ) {
	($b, $bin) = $bin =~ /(.)(.*)/s; $b = ord ($b);
	if ( $b >= @opc00 ) {
	    if ( $b >= 32 && $b <= 246 ) {
		$val = $b - 139;
	    }
	    elsif ( $b >= 247 && $b <= 250 ) {
		$c = $b;
		($b, $bin) = $bin =~ /(.)(.*)/s; $b = ord ($b);
		$val = ($b - 247) * 256 + 108 + $c;
	    }
	    elsif ( $b >= 251 && $b <= 254 ) {
		$c = $b;
		($b, $bin) = $bin =~ /(.)(.*)/s; $b = ord ($b);
		$val = -($b - 251) * 256 - 108 - $c;
	    }
	    elsif ( $b == 255 ) {
		$c = $b;
		($b, $bin) = $bin =~ /(....)(.*)/s;
		$b = unpack ("v", $b);
		$val = $b;
		# sign extension?
	    }
	    $newdata .= $val;
	}
	elsif ( $b == 12 ) {
	    ($b, $bin) = $bin =~ /(.)(.*)/s; $b = ord ($b);
	    if ( $c = defined $opc12[$b] ) {
		$newdata .= $c;
	    }
	    else {
		$newdata .= "UNK12_$b";
	    }
	}
	elsif ( $c = defined $opc00[$b] ) {
	    $newdata .= $c;
	}
	else {
	    $newdata .= "UNK_$b";
	}
	$newdata .= "\n";
    }
    print STDOUT ($newdata);
}

1;
