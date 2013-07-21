#!/usr/bin/perl -s
use strict;
 
local $/;
my $text = <>;
chomp $text;
my @a = split /\s+/ => $text;
 
while( scalar @a > 1 ){
	my $x = shift @a;
	print "$x $a[0]\n";
}
