use utf8;
use strict;
binmode STDIN,":utf8";
binmode STDOUT,":utf8";
binmode STDERR,":utf8";

my @stack=();
my $prev="";
my $count=0;
while (my $in=<STDIN>){
    chomp($in);
    if( $in=~/^$/){
	next;
    }
    if ( $in=~/^\(/ && scalar(@stack) > 0){
	my $out=join(" ",@stack);
	$out =~s/ \)/\)/g;
	print "$out\n";
	@stack=();
    }
    $in =~ s/\(/ (/g;
    $in =~ s/\)/) /g;
    $in =~ s/ +/ /g;
    my @sequence =split(" ",$in);
    for my $str (@sequence){
	#print STDERR "$str\tSTACK: ".join("/".@stack)." ||| ".join("/",@output)."\n";
        if($str =~ /^\(/){
            my $label = $str;
            $label =~ s/\(//g;
	    if ( $label eq "-NONE-"){
		push(@stack, "(-NONE-");
		$prev = "-NONE-";
		#$prev = "("; ### if you do not want to remove -NONE-
	    }else{
		if ( $label ne "-LRB-" &&
		     $label ne "-RRB-" ){
		    $label = (split(/[-=]/, $label))[0]; # REMOVE function tag
		    #$label = (split("-", $label))[0]; # REMOVE function tag (but keep =2 tag)
		}
		push(@stack, "($label");
		$prev = '(';
	    }
	    #print STDERR "#### OPEN $str\tSTACK: ".(join("/",@stack))."\n";
        }elsif($str =~ /\)$/){
	    if($prev eq "-NONE-"){ # REMOVE Empty
		my $p = pop(@stack);
		if ( $p=~/\)$/){
		    push(@stack, $p);
		    push(@stack, $str);
		    $prev = ")";
		}else{
		    $prev = "-NONE-";
		}
	    }elsif($prev eq '('){ # case of a leaf node
	       push(@stack, "$str");
	       $prev = ')';
	    }elsif($prev eq ')'){ # case of a leaf node
	       push(@stack, "$str");
	       $prev = ')';
            }else{
		print STDERR "$str ||| $prev\n";
		die;
	    }
	    #print STDERR "#### CLOSE $str\tSTACK: ".(join("/",@stack))."\n";
        }else{
	    die
	}
	$count++;
    }
}
if (scalar(@stack) > 0){
    my $out=join(" ",@stack);
    $out =~s/ \)/\)/g;
    print "$out\n";
    @stack=();
}
