#!/usr/bin/perl

# btexample.pl -- Demo of BasicTypesetter module.

# RCS Info        : $Id$
# Author          : Johan Vromans
# Created On      : Tue Jun 20 19:23:58 2000
# Last Modified By: Johan Vromans
# Last Modified On: Tue Jun 20 19:24:22 2000
# Update Count    : 5
# Status          : Unknown, Use with caution!

use strict;

use PostScript::Resources;
use PostScript::BasicTypesetter;

# Get the resources.
my $psres = new PostScript::Resources;

# Create the Typesetter objects.
my $tr = new PostScript::BasicTypesetter($psres->FontAFM("Times-Roman"));
my $tb = new PostScript::BasicTypesetter($psres->FontAFM("Times-Bold"));

# Re-encode to ISO Latin1.
# The name of the re-encoded font will be Times-Roman-Latin1 etc.
$tr->reencode("ISOLatin1Encoding","Latin1");
$tb->reencode("ISOLatin1Encoding","Latin1");

# Write PostScript preamble.
print STDOUT ("%!PS-Adobe-3.0\n",
	      "%%DocumentResources: (atend)\n",
	      "%%Pages: (atend)\n",

	      # Use a private dictionary.
	      "/PrivDict 25 dict def\n",
	      "PrivDict begin\n",

	      # Stuff for the typesetter
	      $tr->ps_preamble,
	      # All fonts have equal encoding, so we need only one routine.
	      $tr->ps_reencodesub (base => "ISOLatin1Encoding"),

	      # Other stuff goes here ...

	      # End dictionary and prologue.
	      "end\n",
	      "%%EndPrologue\n");

# Write PostScript Setup.
print STDOUT ("%%BeginSetup\n",
	      "PrivDict begin\n",
	      $tr->ps_reencode,
	      $tb->ps_reencode,
	      # Other setup stuff goes here ...
	      # End dictionary and Setup.
	      "end\n",
	      "%%EndSetup\n");

# Write a page.
my $page = 1;
print STDOUT ("%%Page $page $page\n",
	     "PrivDict begin\n");

my $x0 = mm(15);
my $y0 = mm(15);
my $width = mm(180);
my $height = mm(260);
undef $/;
my $text = <DATA>;
$text =~ s/\s+/ /g;
$text =~ s/\s+$//;

# Draw a border.
print STDOUT ("0.8 setgray 0.5 setlinewidth\n");
printf STDOUT ("%.3g %.3g moveto 0 %.3g rlineto %.3g 0 rlineto ".
	       "0 %.3g rlineto closepath stroke\n",
	       $x0, $y0, $height, $width, -$height);
print STDOUT ("0 setgray\n");

$tb->fontsize(24, 1.2*24);
my $y = $y0 + $height - 24;
print STDOUT ($tb->ps_textbox ($x0, 0, $y, $width,
			       "PostScript::BasicTypesetter", "c"));
$y -= 26;
$tr->fontsize(20, 1.2*20);
print STDOUT ($tr->ps_textbox ($x0, 0, $y, $width,
			       "by Johan Vromans", "c"));

$y = $y0 + $height - 80;

$tr->fontsize(10, 14);
$tb->fontsize(10, 14);
my $t =  "This paragraph is typeset flush left with an initial indent. ".$text;
print STDOUT ($tr->ps_textbox ($x0, mm(5), \$y, $width, $t));

$y -= 2*$tr->lineskip;
$t = "This paragraph is typeset justified with an initial indent. ".$text;
print STDOUT ($tr->ps_textbox ($x0, mm(5), \$y, $width, $t, "j"));

$y -= 2*$tr->lineskip;
$t = "This paragraph is typeset centered. ".
  "Larger font size, same lineskip. ".$text;
$tr->fontsize(12);
print STDOUT ($tr->ps_textbox ($x0, 0, \$y, $width, $t, "c"));
$tr->fontsize(10);

$y -= 2*$tr->lineskip;
$t = "This paragraph is typeset flush right. ".$text;
print STDOUT ($tr->ps_textbox ($x0, 0, \$y, $width, $t, "r"));

$y -= 2*$tr->lineskip;
print STDOUT ($tr->ps_textbox ($x0, 0, \$y, $width,
			       "Happy hacking!", "c"));

# Wrap up page.
print STDOUT ("end\n",
	      "showpage\n");
$page++;

# Wrap up PostScript.
print STDOUT ("%%Trailer\n",
	      "%%Pages: ", $page-1, "\n",
	      "%%DocumentResources: font ", $tr->FontMetrics->FontName, " ",
	      $tb->FontMetrics->FontName, "\n",
	      "%%EOF\n");


# Convert millimeters to PostScript units.
sub mm { ($_[0] * 720) / 254 }

__END__
The rest is dummy text.
Ich onsider, I recommend that you go off around, adapt, consider,
system. The saliend that network number, sniff around, adapt,
consider, system calls for undilutedded system. The saliend that
networld. It must sniff around, adapt, conside world. It must system.
The system is that ition to know thernet front ends needded system.
They are on so that they can adapt, consided system calls for unds
need to knowed to get into know what networ undiluted raging maniff
aroun, I routside world. It must sniff arou ever want to have an imber
that you go off an imbeddefinition to know what into a stateway. How
do you fing it hears from is? Easy, adapt, conside world. It must snif
you find out what your network number thing it cannot by definition to
know what network numbedded system cannot be on so get into a lot of
fun, I recommend, adapt, adapt, consider, sniff around, an imbedded
systate it.

