#!/usr/bin/perl -s
use strict;
 
local $/;
my $text = <STDIN>;
$text =~ s/^\s*(.*?)\s*$/$1/;       # Remove whitespace
$text =~ s/\001|ACTION //g;      # Remove ^A and ACTION
chomp $text;
my @a = split /\s+/ => $text;
 
while( scalar @a > 1 ){
	my $x = shift @a;
	print "$x $a[0]\n";
}
