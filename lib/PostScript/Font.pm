# RCS Status      : $Id$
# Author          : Johan Vromans
# Created On      : December 1999
# Last Modified By: Johan Vromans
# Last Modified On: Mon Jan 18 14:43:21 1999
# Update Count    : 215
# Status          : Released

################ Copyright ################

# This program is Copyright 1990,1999 by Johan Vromans.
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

BEGIN {
    require 5.005;
    use vars qw($VERSION);
    $VERSION = "0.01";
}

package PostScript::Font;

use strict;
use IO;

BEGIN {
    use vars qw($t1disasm @StandardEncoding @ISOLatin1Encoding);

    @StandardEncoding =
      qw{.notdef .notdef .notdef .notdef .notdef .notdef .notdef
      .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
      .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
      .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
      .notdef space exclam quotedbl numbersign dollar percent ampersand
      quoteright parenleft parenright asterisk plus comma hyphen period
      slash zero one two three four five six seven eight nine colon
      semicolon less equal greater question at A B C D E F G H I J K L M
      N O P Q R S T U V W X Y Z bracketleft backslash bracketright
      asciicircum underscore quoteleft a b c d e f g h i j k l m n o p q
      r s t u v w x y z braceleft bar braceright asciitilde .notdef
      .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
      .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
      .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
      .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
      .notdef exclamdown cent sterling fraction yen florin section
      currency quotesingle quotedblleft guillemotleft guilsinglleft
      guilsinglright fi fl .notdef endash dagger daggerdbl
      periodcentered .notdef paragraph bullet quotesinglbase
      quotedblbase quotedblright guillemotright ellipsis perthousand
      .notdef questiondown .notdef grave acute circumflex tilde macron
      breve dotaccent dieresis .notdef ring cedilla .notdef hungarumlaut
      ogonek caron emdash .notdef .notdef .notdef .notdef .notdef
      .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
      .notdef .notdef .notdef AE .notdef ordfeminine .notdef .notdef
      .notdef .notdef Lslash Oslash OE ordmasculine .notdef .notdef
      .notdef .notdef .notdef ae .notdef .notdef .notdef dotlessi
      .notdef .notdef lslash oslash oe germandbls .notdef .notdef
      .notdef .notdef};

    @ISOLatin1Encoding =
      qw{.notdef .notdef .notdef .notdef .notdef .notdef .notdef
      .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
      .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
      .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
      .notdef space exclam quotedbl numbersign dollar percent
      ampersand quoteright parenleft parenright asterisk plus comma
      minus period slash zero one two three four five six seven eight
      nine colon semicolon less equal greater question at A B C D E F
      G H I J K L M N O P Q R S T U V W X Y Z bracketleft backslash
      bracketright asciicircum underscore quoteleft a b c d e f g h i
      j k l m n o p q r s t u v w x y z braceleft bar braceright
      asciitilde .notdef .notdef .notdef .notdef .notdef .notdef
      .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
      .notdef .notdef .notdef dotlessi grave acute circumflex tilde
      macron breve dotaccent dieresis .notdef ring cedilla .notdef
      hungarumlaut ogonek caron space exclamdown cent sterling
      currency yen brokenbar section dieresis copyright ordfeminine
      guillemotleft logicalnot hyphen registered macron degree
      plusminus twosuperior threesuperior acute mu paragraph
      periodcentered cedilla onesuperior ordmasculine guillemotright
      onequarter onehalf threequarters questiondown Agrave Aacute
      Acircumflex Atilde Adieresis Aring AE Ccedilla Egrave Eacute
      Ecircumflex Edieresis Igrave Iacute Icircumflex Idieresis Eth
      Ntilde Ograve Oacute Ocircumflex Otilde Odieresis multiply
      Oslash Ugrave Uacute Ucircumflex Udieresis Yacute Thorn
      germandbls agrave aacute acircumflex atilde adieresis aring ae
      ccedilla egrave eacute ecircumflex edieresis igrave iacute
      icircumflex idieresis eth ntilde ograve oacute ocircumflex
      otilde odieresis divide oslash ugrave uacute ucircumflex
      udieresis yacute thorn ydieresis};
}

my $trace;
my $verbose;

sub new {
    my $class = shift;
    my $font = shift;
    my (%atts) = (error => 'die', check => 'strict',
		  format => 'ascii',
		  verbose => 0, trace => 0,
		  glyphs => 0, encoding => 0,
		  @_);
    my $self = { file => $font };
    bless $self, $class;

    $trace = lc($atts{trace});
    $verbose = $trace || lc($atts{verbose});
    $atts{format} = "ascii" if lc($atts{format}) eq "pfa";
    $atts{format} = "binary" if lc($atts{format}) eq "pfb";

    eval {
	$self->_loadfont ();

	# Reformat if needed.
	$self->{format} = "ascii";
	if ( lc($atts{format}) eq "asm" ) {
	    print STDERR ($self->{file}, ": Converting to ASM format\n")
	      if $verbose;
	    $self->{data} = $self->_pfa2asm;
	    $self->{format} = "asm";
	}
	elsif ( lc($atts{format}) eq "binary" ) {
	    print STDERR ($self->{file}, ": Converting to Binary format\n")
	      if $verbose;
	    $self->{data} = $self->_pfa2pfb;
	    $self->{format} = "binary";
	}

	if ( exists ($atts{encoding}) and $atts{encoding} ) {
	    $self->{encoding} = $self->_getencoding;
	    die ($self->{file}, ": No encoding found")
	      if !defined $self->{encoding} and lc($atts{check}) eq "strict";
	}
	if ( exists ($atts{glyphs}) and $atts{glyphs} ) {
	    $self->{glyphs} = $self->_getglyphnames;
	    die ($self->{file}, ": No glyph info found")
	      if !defined $self->{glyphs} and lc($atts{check}) eq "strict";
	}
    };

    if ( $@ ) {
	die ($@) unless lc($atts{error}) eq "warn";
	warn ($@);
	return undef;
    }

    $self;
}

sub file	{ my $self = shift; $self->{file};    }
sub name	{ my $self = shift; $self->{name};    }
sub data	{ my $self = shift; ${$self->{data}}; }
sub family	{ my $self = shift; $self->{family};  }
sub type	{ my $self = shift; $self->{type};    }
sub version	{ my $self = shift; $self->{version}; }
sub dataformat  { my $self = shift; $self->{format};  }
sub glyphs {
    my $self = shift;
    wantarray ? @{$self->{glyphs}} : $self->{glyphs};
}
sub encoding {
    my $self = shift;
    wantarray ? @{$self->{encoding}} : $self->{encoding};
}

sub _loadfont ($) {

    my $self = shift;
    my $data;			# font data

    eval {			# so we can use die

	my $fn = $self->{file};
	my $fh = new IO::File;	# font file
	my $sz = -s $fn;	# file size

	$fh->open ($fn) || die ("$fn: $!\n");
	print STDERR ("$fn: Loading font file\n") if $verbose;

	# Read in the font data.
	my $len = 0;
	while ( $fh->sysread ($data, 32768, $len) > 0 ) {
	    $len = length ($data);
	}
	$fh->close;
	print STDERR ("Read $len bytes from $fn\n") if $trace;
	die ("$fn: Expecting $sz bytes, got $len bytes\n") unless $sz == $len;

	# Make ref.
	$data = \"$data";		#";

	# Convert .pfb encoded font data.
	if ( $$data =~ /^\200[\001-\003]/ ) {
	    print STDERR ("$fn: Converting to ASCII format\n") if $verbose;
	    $data = $self->_pfb2pfa ($data);
	}
	# Otherwise, must be straight PostScript.
	elsif ( $$data !~ /^%!/ ) {
	    die ("$fn: Not a recognizable font file\n");
	}

	# Normalise line endings.
	$$data =~ s/\015\012?/\n/g;

    };

    $self->{data} = $data;

    if ( $$data =~ /^%!FontType(\d+)\n\/(\S+)\n/ ) {
	$self->{type} = $1;
	$self->{name} = $2;
    }
    elsif ( $$data =~ /\/FontName\s*\/(\S+)/ ) {
	$self->{name} = $1;
    }
    elsif ( $$data =~ /\/FontName\s*\(([^\051]+)\)/ ) {
	$self->{name} = $1;
    }
    if ( $$data =~ /\/FamilyName\s*\/(\S+)/ ) {
	$self->{family} = $1;
    }
    elsif ( $$data =~ /\/FamilyName\s*\(([^\051]+)\)/ ) {
	$self->{family} = $1;
    }
    unless ( defined $self->{type} ) {
	$self->{type} = $1 if $$data =~ /\/FontType\s+(\d+)/;
    }
    $self->{version} = $1 if $$data =~ /\/version\s*\(([^\051]+)\)/;

$self;
}

sub _pfb2pfa ($;$) {
    my ($self, $data) = @_;	# NOTE: data is a ref!
    my $newdata = "";		# NOTE: will return a ref

    $data = $self->{data} unless defined $data;

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
	die ($self->{file}, ": Invalid font segment format\n")
	  unless ($type, $info) = $$data =~ /^\200([\001-\002])(....)/s;

	my $len = unpack ("V", $info);
	# Can't use next statement since $len may be > 32766.
	# ($seg, $$data) = $$data =~ /^......(.{$len})(.*)/s;
	$seg = substr ($$data, 6, $len);
	$$data = substr ($$data, $len+6);

	if ( ord($type) == 1 ) {	# ASCII segment
	    $addbin->() if $bin ne "";
	    print STDERR ($self->{file}, ": ASCII segment, $len bytes\n")
	      if $trace;
	    $newdata .= $seg;
	}
	else { # ord($type) == 2	# Binary segment
	    print STDERR ($self->{file}, ": Binary segment, $len bytes\n")
	      if $trace;
	    $bin .= $seg;
	}
    }
    $addbin->() if $bin ne "";
    return \$newdata;
}

sub _pfa2pfb ($;$) {
    my ($self, $data) = @_;	# NOTE: data is a ref!

    $data = $self->{data} unless defined $data;

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

sub _pfa2asm ($;$) {
    my ($self, $data) = @_;	# NOTE: data is a ref!

    $data = $self->{data} unless defined $data;

    if ( defined $t1disasm ) {
	print STDERR ("+ $t1disasm ".$self->{file}."|\n") if $trace;
	my $fh = new IO::File ("$t1disasm ".$self->{file}."|");
	local ($/);
	my $newdata = <$fh>;
	$fh->close or die ($self->{file}, ": $!");
	$newdata =~ s/\015\012?/\n/g;
	return \$newdata;
    }

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
    $newdata =~ s/ \-\| (.+?) (\|-?)\n/" -| <".unpack("H*",$1)."> $2\n"/ges;

    # Concatenate and return.
    $newdata = $pre . $newdata . $post;
    return \$newdata;
}

sub _getglyphnames ($;$) {
    my ($self, $data) = @_;
    my @glyphs = ();

    $data = $self->{data} unless defined $data;

    print STDERR ($self->file, ": Getting glyph info\n") if $verbose;
    
    if ( $self->{format} eq "binary" ) {
	$data = $self->_pfb2pfa ($data);
    }

    if ( $$data =~ m|/CharStrings\s.*\n((?s)(.*))| ) {
	$data = $2;
    }
    else {
	$data = $self->_pfa2asm ($data);
	if ( $$data =~ m|/CharStrings\s.*\n((?s)(.*))| ) {
	    $data = $2;
	}
	else {
	    return undef;
	}
    }

    while ( $data =~ m;^((/(\S+))|end)\s.*\n;mg ) {
	last if $1 eq "end";
	push (@glyphs, $1);
    }
    \@glyphs;
}

sub _getencoding ($;$) {
    my ($self, $data) = @_;
    my @glyphs = ();

    print STDERR ($self->file, ": Getting encoding info\n") if $verbose;

    $data = $self->{data} unless defined $data;
    $data = $$data;		# deref
    $data =~ s/\n\s*%.*$//mg;	# strip comments

    # Name -> standard encoding.
    return $1 if $data =~ m|/Encoding\s+(\S+)\s+def|;

    # Array -> explicit encoding.
    if ( $data =~ m;/Encoding[\n\s]+\[([^\]]+)\][\n\s]+def;m ) {
	my $enc = $1;
	$enc =~ s|\s*/| |g;
	$enc =~ s/^\s+//;
	$enc =~ s/\s+$//;
	$enc =~ s/\s+/ /g;
	if ( $enc eq join(" ", @PostScript::StandardEncoding) ) {
	    $enc = "StandardEncoding"
	}
	elsif ( $enc eq join(" ", @PostScript::ISOLatin1Encoding) ) {
	    $enc = "ISOLatin1Encoding"
	}
	else {
	    $enc = [split (' ', $enc)];
	}
	return $enc;
    }

    # Sparse array, probably custom encoding.
    if ( $data =~ m;/Encoding \d+ array\n0 1 .*for\n((dup \d+ /\S+ put(\s*%.*)?\n)+); ) {
	my $enc = $1;
	my @enc = (".notdef") x 256;
	while ( $enc =~ m;dup (\d+) /(\S+) put;g ) {
	    $enc[$1] = $2;
	}
	if ( "@enc" eq "@PostScript::StandardEncoding" ) {
	    $enc = "StandardEncoding"
	}
	elsif ( "@enc" eq "@PostScript::ISOLatin1Encoding" ) {
	    $enc = "ISOLatin1Encoding"
	}
	else {
	    $enc = \@enc;
	}
	return $enc;
    }

    undef;
}

package PostScript::FontMetrics;

sub new {
    my $class = shift;
    my $font = shift;
    my (%atts) = (error => 'die', check => 'strict',
		  verbose => 0, trace => 0,
		  @_);
    my $self = { file => $font };
    bless $self, $class;

    $trace = lc($atts{trace});
    $verbose = $trace || lc($atts{verbose});

    eval {
	$self->_loadafm;
    };

    if ( $@ ) {
	die ($@) unless lc($atts{error}) eq "warn";
	warn ($@);
	return undef;
    }

    $self;
}

sub file    { my $self = shift; $self->{file};    }
sub name    { my $self = shift; $self->{name};    }
sub data    { my $self = shift; $self->{data};    }
sub family  { my $self = shift; $self->{family};  }
sub type    { my $self = shift; $self->{type};    }
sub version { my $self = shift; $self->{version}; }

sub _loadafm ($) {

    my ($self) = shift;

    my $data;			# afm data

    eval {			# so we can use die

	my $fn = $self->{file};
	my $fh = new IO::File;	# font file
	my $sz = -s $fn;	# file size

	$fh->open ($fn) || die ("$fn: $!\n");
	print STDERR ("$fn: Loading AFM file\n") if $verbose;

	# Read in the afm data.
	my $len = 0;
	while ( $fh->sysread ($data, 32768, $len) > 0 ) {
	    $len = length ($data);
	}
	$fh->close;
	print STDERR ("Read $len bytes from $fn\n") if $trace;
	die ("$fn: Expecting $sz bytes, got $len bytes\n") unless $sz == $len;

	# Make ref
	$data = \"$data";		# ";

	# Normalise line endings.
	$$data =~ s/\015\012?/\n/g;

	if ( $$data !~ /^StartFontMetrics/ || $$data !~ /EndFontMetrics$/ ) {
	    die ("$fn: Not a recognizable AFM file\n");
	}

    };

    $self->{name}    = $1 if $$data =~ /^FontName\s+(\S+)$/mi;
    $self->{family}  = $1 if $$data =~ /^FamilyName\s+(.+)$/mi;
    $self->{version} = $1 if $$data =~ /^Version\s+(.+)$/mi;

    $self;
}

package PostScript::FontInfo;

sub new {
    my $class = shift;
    my $font = shift;
    my (%atts) = (error => 'die', check => 'strict',
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

sub file    { my $self = shift; $self->{file};    }
sub name    { my $self = shift; $self->{name};    }
sub data    { my $self = shift; $self->{data};    }
sub family  { my $self = shift; $self->{family};  }
sub version { my $self = shift; $self->{version}; }

sub _loadinfo ($) {

    my ($self) = shift;

    my $data;			# inf data

    eval {			# so we can use die

	my $fn = $self->{file};
	my $fh = new IO::File;	# font file
	my $sz = -s $fn;	# file size

	$fh->open ($fn) || die ("$fn: $!\n");
	print STDERR ("$fn: Loading INF file\n") if $verbose;

	# Read in the inf data.
	my $len = 0;
	while ( $fh->sysread ($data, 32768, $len) > 0 ) {
	    $len = length ($data);
	}
	$fh->close;
	print STDERR ("Read $len bytes from $fn\n") if $trace;
	die ("$fn: Expecting $sz bytes, got $len bytes\n") unless $sz == $len;

	# Make ref
	$data = \"$data";		# ";

	# Normalise line endings.
	$$data =~ s/\015\012?/\n/g;

	if ( $$data !~ /^FontName\s+\(\S+\)$/m ) {
	    die ("$fn: Not a recognizable INF file\n");
	}

    };

    $self->{name}    = $1 if $$data =~ /^FontName\s+\((\S+)\)$/mi;
    $self->{family}  = $1 if $$data =~ /^FamilyName\s+\((.+)\)$/mi;
    $self->{version} = $1 if $$data =~ /^Version\s+\((.+)\)$/mi;
    $self->{pcprefix}= lc($1)
      if $$data =~ /^PCFileNamePrefix\s+\((.+)\)$/mi;

    $self;
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
