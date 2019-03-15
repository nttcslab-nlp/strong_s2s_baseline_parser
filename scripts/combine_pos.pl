#/bin/perl

use strict;

print STDERR "# $ARGV[0]\n";
open(IN,$ARGV[0]) ||die;

my @cache;
while(my $in=<IN>){
    chomp($in);
    push(@cache, $in);
}
close(IN);
my $dict_size=scalar(@cache);
print STDERR "$dict_size\n";

my $c=0;
while(my $in=<STDIN>){
    chomp($in);    

    my @pos = split('\s+',$cache[$c]);
    my @line = split('\s+',$in); 
    my $pos_size=scalar(@pos);
    #print join(' ',@pos);
    
    my $out="";
    my $z=0;
    foreach my $l (@line){
	if( $l eq "XX"
	    || $l eq "."
	    || $l eq ","
	    || $l eq "''"
	    || $l eq "``"
	    || $l eq ":"
	    ){
	    $out.="_$pos[$z]_ ";
	    $z++;
	}else{
	    $out.="$l ";
	}
    }
    die if $z != $pos_size && print "$c $z $pos_size ||| $in ||| $pos[$c]\n"; 
    print "$out\n";
    $c++;
}

print STDERR "DONE. $c\n"
