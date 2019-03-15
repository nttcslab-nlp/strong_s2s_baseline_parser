binmode STDIN,":utf8";
binmode STDOUT,":utf8";
binmode STDERR,":utf8";

my $ncol = $ARGV[0];
my $tcol = $ARGV[1];
my $out="";

while(my $line=<STDIN>){
    chomp($line);
    my @f = split(/\s+/,$line);
    if (scalar(@f) == 0){
	chomp($out);
	print "$out\n";
	$out="";
	next;
    }
    die if (scalar(@f) < $tcol);
    $out.="$f[$ncol] ";
}
