use strict;
binmode STDIN,":utf8";
binmode STDOUT,":utf8";
binmode STDERR,":utf8";

open(IN1, $ARGV[0]) || die;
open(IN2, $ARGV[1]) || die;

my $line1="";
my $line2="";
while(1){
    last if(!($line1=<IN1>));
    last if(!($line2=<IN2>));
    chomp($line1);
    chomp($line2);

    my @f = split(' ',$line2);
    for(my $i=0; $i<scalar(@f); $i++){
	$f[$i] ="B:$f[$i]";
    }
    $line2=join(" ",@f);
    $line2 =~ s/@@ /@@|||/g;
    my @f1 = split(' ',$line1);
    my @f2 = split(' ',$line2);
    #print "$line1\t$line2\n";
    #print scalar(@f1);
    #print scalar(@f2);
    die if scalar(@f1) != scalar(@f2);
    my $out="";
    for(my $i=0; $i<scalar(@f1); $i++){
	$out.="$f1[$i]|||$f2[$i] ";
    }
    $out =~ s/\|\|\|B:/|||<unk>|||B:/g;
    chop($out);
    print "$out\n";
}
