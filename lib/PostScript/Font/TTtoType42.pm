# RCS Status      : $Id$
# Author          : Johan Vromans
# Created On      : Mon Dec 16 18:56:03 2002
# Last Modified By: Johan Vromans
# Last Modified On: Wed Dec 18 18:46:27 2002
# Update Count    : 43
# Status          : Released

################ Module Preamble ################

package Font::TTF::Type42;

use 5.006;

use strict;
use warnings;

our $VERSION = "0.01";

use base qw(Font::TTF::Font);

use constant CHUNK => 65534;
use constant DEBUG => 0;

################ Public Methods ################

sub write {
    my ($self, $file) = @_;

    CORE::open(my $fd, ">", $file) or die("$file: $!\n");
    print $fd (${$self->as_string});
    close($fd);
    $self;
}

sub as_string {
    my ($self) = @_;

    # Read some tables.
    my $head = $self->{head}->read;
    my $name = $self->{name}->read;
    my $post = $self->{post}->read;

    # Version. Try to normalize to nnn.nnn.
    my $version = $self->_str(5);
    $version = sprintf("%07.3f", $1) if $version =~ /(\d+\.\d+)/;

    # Font bounding box.
    my $u = $head->{unitsPerEm};
    my @bb = (int($head->{xMin} * 1000 / $u),
	      int($head->{yMin} * 1000 / $u),
	      int($head->{xMax} * 1000 / $u),
	      int($head->{yMax} * 1000 / $u));

    # Glyph table.
    my $glyphs = $self->glyphs;

    # Start font information.
    my $ret = "%!PS-TrueTypeFont" .
              "-" . sprintf("%07.3f", $self->{head}{version}) .
              "-" . $version .
              "\n" .
              "%%Creator: " . __PACKAGE__ . " " . $VERSION .
	      " by Johan Vromans\n" .
	      "%%CreationDate: " . localtime(time) . "\n";

    $ret .= "11 dict begin\n";
    $self->_addstr(\$ret, "FontName", 6, 1);
    $ret .= "/FontType 42 def\n" .
            "/FontMatrix [1 0 0 1 0 0] def\n" .
	    "/FontBBox [@bb] def\n" .
	    "/PaintType 0 def\n" .
	    "/FontInfo 9 dict dup begin\n" .
	    "/version (" . _psstr($version) . ") readonly def\n";
    # $self->_addstr(\$ret, "Notice",     0);
    $self->_addstr(\$ret, "FullName",   4);
    $self->_addstr(\$ret, "FamilyName", 1);
    $self->_addstr(\$ret, "Weight",     2);
    $self->_addnum(\$ret, "ItalicAngle",        $post->{italicAngle});
    $self->_addbool(\$ret,"isFixedPitch",       $post->{isFixedPitch});
    $self->_addnum(\$ret, "UnderlinePosition",  $post->{underlinePosition});
    $self->_addnum(\$ret, "UnderlineThickness", $post->{underlineThickness});
    $ret .= "end readonly def\n" .
            "/Encoding StandardEncoding def\n";

    # CharStrings definitions.
    $ret .= "/CharStrings " . scalar(@$glyphs) . " dict dup begin\n";
    my $i = 0;
    foreach ( @$glyphs ) {
	$ret .= "/$_ $i def\n";
	$i++;
    }
    $ret .= "end readonly def\n";

    # TrueType strings table.
    $ret .= "/sfnts[<\n";

    my @tables = ('cvt ', 'fpgm', 'glyf', 'head', 'hhea', 'hmtx', 'loca',
		  'maxp', 'prep');

    # Count the number of tables actually present.
    my $tables = 0;
    foreach my $t ( @tables ) {
	next unless $self->{$t};
	next unless $self->{$t}->{' LENGTH'};
	$tables++;
    }

    my $start = 12 + 16 * $tables;
    my $dir = _dirhdr($tables);
    my $fd = $self->{' INFILE'};

    # Create dir entries and calculate the new 'head' checksum.
    my $csum = 0xB4DED201;
    { use integer;
      foreach my $t ( @tables ) {
	next unless $self->{$t};
	my $off = $self->{$t}->{' OFFSET'};
	my $len = $self->{$t}->{' LENGTH'};
	my $sum = $self->{$t}->{' CSUM'};
	$dir .= sprintf("%s%08X%08X%08X\n",
			uc unpack("H8", $t), $sum, $start, $len);
	$csum += $sum + $sum + $start + $len;
	$start += $len;
	$start += 2 if $start % 4;
      }
      $csum &= 0xffffffff;
      $csum = 0xb1b0afba - $csum;
    }

    # Add dir info and prepare for the tables.
    $ret .= $dir;
    my $tally = length($dir) / 2;
    my $data = "";

    my $ship = sub {
	$data =~ s/(.{72})/$1\n/g;
	$ret .= $data . "\n00><\n";
	$data = "";
	$tally = 0;
    };

    foreach my $t ( @tables ) {
	next unless $self->{$t};
	my $len = $self->{$t}->{' LENGTH'};
	next unless $len;	# to make sure.

	printf STDERR ("$t: off = 0x%x, len = 0x%x, csum = 0x%x\n",
		       $self->{$t}->{' OFFSET'}, $len,
		       $self->{$t}->{' CSUM'}) if DEBUG;

	# If the glyf table is bigger than a CHUNK, it must be split on 
	# a glyph boundary...
	if ( $t eq "glyf" && $len > CHUNK ) {
	    $self->_glyftbl(\$data, \$tally, $ship, $fd,
			    $self->{glyf}->{' OFFSET'}, $len,
			    $self->{loca}->{' OFFSET'},
			    $self->{loca}->{' LENGTH'});
	}
	else {
	    # Ship current sfnts string if this table does not fit.
	    if ( $tally + $len > CHUNK ) {
		$ship->();
	    }

	    # Read table, and convert to hex data.
	    my $off = $self->{$t}->{' OFFSET'};
	    sysseek($fd, $off, 0);
	    while ( $len > 0 ) {
		my $dat;
		my $l = $len >= 1024 ? 1024 : $len;
		sysread($fd, $dat, $l);
		if ( $t eq "head" ) {
		    # Move new checksum in.
		    substr($dat,8,4) = pack("N",$csum)
		}
		$len -= $l;
		$tally += $l;
		$l += $l;
		$data .= uc unpack("H$l", $dat);
	    }
	}

	# Pad to 4-byte boundary if necessary.
	if ( $self->{$t}->{' LENGTH'} & 0x3 ) {
	    printf STDERR ("odd length 0x%x, adjusting...\n", $_) if DEBUG;
	    $data .= "0000";
	    $tally += 2;
	}
    }

    # Format and terminate pending sfnts string.
    $data =~ s/(.{72})/$1\n/g;
    $ret .= $data . "\n00>";

    # Finish font info.
    $ret .= "]def\n" .
	    "FontName currentdict end definefont pop\n";

    # Return ref to the info.
    \$ret;
}

# Ordered set of glyphs, as they appear in the font.
sub glyphs {
    my $self = shift;
    $self->{glyphs} ||= $self->_getglyphs;
}

# Sorted list of glyph names, no duplicates.
sub glyphnames {
    my $self = shift;
    return $self->{glyphnames} if exists $self->{glyphnames};
    my %glyphs = map { $_ => 1 } @{$self->glyphs};
    $self->{glyphnames} = [ sort keys %glyphs ];
}

sub write_afm {
    my ($self, $file) = @_;
}

################ Internal routines ################

sub _dirhdr {
    my $tables = shift;
    my $searchrange = 1;
    my $entryselector = 0;

    while ( $searchrange <= $tables ) {
	$searchrange *= 2;
	$entryselector++;
    }
    $searchrange = 16 * ($searchrange/2);
    $entryselector--;
    my $rangeshift = 16 * $tables - $searchrange;

    sprintf("00010000%02hX%02hX%02hX%02hX%02hX%02hX%02hX%02hX\n",
	    $tables        >> 8, $tables        & 0xff,
	    $searchrange   >> 8, $searchrange   & 0xff,
	    $entryselector >> 8, $entryselector & 0xff,
	    $rangeshift    >> 8, $rangeshift    & 0xff);
}

sub _str {
    my ($self, $idx) = @_;
    $self->{name}{strings}[$idx][1][0]{0} || "";
}

sub _addstr {
    my ($self, $ret, $tag, $idx, $name) = @_;
    my $t = $self->_str($idx);
    return unless $t ne "";
    if ( $name && $t =~ /^[-\w]+$/ ) {
	$$ret .= "/$tag /$t def\n";
    }
    else {
	$t = _psstr($t);
	$$ret .= "/$tag ($t) readonly def\n";
    }
}

sub _psstr {
    my ($str) = @_;
    $str =~ s/([\\()])/\\$1/g;
    $str =~ s/([\000-\037\177-\377])/sprintf("\\%03o",ord($1))/eg;
    $str;
}

sub _addnum {
    my ($self, $ret, $tag, $val) = @_;
    return unless defined $val;
    $$ret .= "/$tag $val def\n";
}

sub _addbool {
    my ($self, $ret, $tag, $val) = @_;
    return unless defined $val;
    $$ret .= "/$tag " .
      ( $val ? "true" : "false" ) . " def\n";
}

sub _getglyphs {
    my $self = shift;
    $self->{post}->read;
    $self->{glyphs} = $self->{post}{VAL};
}

sub _glyftbl {
    my ($self, $rd, $rt, $ship, $fd, $glyf_off, $glyf_len, $loca_off, $loca_len) = @_;

    # To split the glyph table we need to find an appropriate glyph
    # boudary. This requires processing the 'loca' table.

    my $loca = _read_tbl($fd, $loca_off, $loca_len);
    my $glyf = _read_tbl($fd, $glyf_off, $glyf_len);

    my $glyphs = $self->{maxp}->read->{numGlyphs};
    my $locfmt = $self->{head}->read->{indexToLocFormat};
    print STDERR ("glyphs = $glyphs, locfmt  = $locfmt\n") if DEBUG;

    my $start = 0;
    my $off_old = 0;
    my $off;

    for ( my $i = 0; $i <= $glyphs; $i++ ) {
	if ( $locfmt ) {
	    $off = unpack("N", substr($$loca, $i*4, 4));
	}
	else {
	    $off = unpack("n", substr($$loca, $i*2, 2)) * 2;
	}
	if ( $$rt + $off - $start > CHUNK ) {
	    my $l = $off_old - $start;
	    $$rd .= uc unpack("H".($l+$l), substr($$glyf, $start, $l));
	    $start += $l;
	    $ship->();
	}
	$off_old = $off;
    }
    my $l = $glyf_len - $start;
    $$rd .= uc unpack("H".($l+$l), substr($$glyf, $start, $l));
    $$rt += $l;

    printf STDERR ("glyf ends: data = 0x%x, tally = 0x%x\n",
		   length($$rd), $$rt) if DEBUG;
}

sub _read_tbl {
    my ($fd, $off, $len) = @_;
    sysseek($fd, $off, 0);
    my $data = "";
    while ( $len > 0 ) {
	my $l = sysread($fd, $data, $len, length($data));
	last if $l == $len;
	die("read: $!\n") if $l <= 0;
	$len -= $l;
    }
    \$data;
}

1;

__END__

=head1 NAME

Font::TTF::Type42 - Wrap a TrueType font into PostScript Type42

=head1 SYNOPSIS

    use Font::TTF::Type42;
    # Open a TrueType font.
    my $font = Font::TTF::Type42::->open("Arial.ttf");
    # Write a Type42 font.
    $font->write("Arial.t42");
    # Get the font data (scalar ref).
    my $ptr = $font->as_string;
    # Get the font glyph names (array ref).
    my $gref = $font->glyphnames;

=head1 DESCRIPTION

Font::TTF::Type42 is a subclass of Font::TTF::Font. It knows how to
wrap a TrueType font into PostScript Type42 format.

=head1 METHODS

=over

=item open(I<fontname>)

Opens the named TrueType font.

=item as_string

Returns the font data in Type42 format as reference to one single
string. Newlines are embedded for readability.

=item write(I<t42name>)

Writes the font data in Type42 format to the named file.

=item glyphnames

Returns an array reference with the names of all the glyphs of the
font, sorted alphabetically.

=back

=head1 KNOWN BUGS

Certain TrueType fonts cause problems.

CID fonts are not yet supported.

=head1 SEE ALSO

=over 4

=item http://partners.adobe.com/asn/developer/PDFS/TN/5012.Type42_Spec.pdf

The specification of the Type 42 font format.

=item http://fonts.apple.com/TTRefMan/index.html

The True Type reference manual.

=back

=head1 AUTHOR

Johan Vromans, Squirrel Consultancy <jvromans@squirrel.nl>

=head1 COPYRIGHT and DISCLAIMER

This program is Copyright 2002 by Squirrel Consultancy. All
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

# Local Variables:
# compile-command: "perl -Mblib=/home/jv/wrk/Font-TTF-0.32 -MType42 -e 'Font::TTF::Type42->open(q(/home/jv/lib/fonts/ttfonts/g/gara0000))->write(q(xx))'"
# End:
