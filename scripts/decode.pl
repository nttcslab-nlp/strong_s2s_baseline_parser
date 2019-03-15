use utf8;
use strict;

&main();

sub main {
    my $tok_file = $ARGV[0];
    my $pos_file = $ARGV[1];
    my $con_file = $ARGV[2];
    my $out_file = $ARGV[3];
    open(my $tok_fp, $tok_file);
    open(my $pos_fp, $pos_file);
    open(my $con_fp, $con_file);
    open(my $out_fp, ">$out_file");
    while(1){
        my $line_tok = <$tok_fp>;
        my $line_pos = <$pos_fp>;
        my $line_con = <$con_fp>;
	if ($line_con =~/^[0-9]/){
	    print $out_fp "$line_con"; # number of candidates
	    $line_con = <$con_fp>;
	}
	die if ($line_con =~/^[0-9]/);
        chomp($line_tok);
        chomp($line_pos);
        chomp($line_con);
        if(!$line_tok){
            exit(0);
        }
        my @tok = split(/ /, $line_tok);
        my @pos = split(/ /, $line_pos);
        my @con = split(/ /, $line_con);
        my $XX_count = 0;
        my $left_bracket_count = 0;
        my $right_bracket_count = 0;
        for my $elem (@con){
            if($elem eq "XX" || $elem eq "." || $elem eq "," || $elem eq ":" || $elem eq "(" || $elem eq ")" || $elem eq "''" || $elem eq "``" || $elem =~/^_/){
                $XX_count++;
            }elsif($elem =~ /\)/){
                $right_bracket_count++;
            }elsif($elem =~ /\(/){
                $left_bracket_count++;
            }elsif($elem =~ /<unk>/ || $elem =~ /<s>/ || $elem =~ /<\/s>/){
                next;
            }else{
                print STDERR "File format is wrong.\n";
                print STDERR $line_con."\n";
                exit(1);
            }
        }
        if(scalar(@tok) != scalar(@pos)){
            print STDERR "Token size and POS size are not same.\n";
            #print STDERR $line_con."\n";
            exit(1);
        }
        if(scalar(@pos) > $XX_count){
            my $XX_count_local = 0;
            my $body = "";
            for my $elem (@con){
                if($elem eq "XX" || $elem eq "." || $elem eq "," || $elem eq ":" || $elem eq "(" || $elem eq ")" || $elem eq "''" || $elem eq "``" || $elem =~/^_/){
                    $elem = "(".$pos[$XX_count_local]." ".$tok[$XX_count_local].")";
                    if($body ne ""){
                        $elem = " ".$elem;
                    }
                    $XX_count_local++;
                }elsif($elem =~ /\)/){
                    my @col = split(/_/, $elem);
                    $elem = $col[0];
                }elsif($elem =~ /\(/){
                    if($body ne ""){
                        $elem = " ".$elem;
                    }
            	}elsif($elem =~ /<unk>/ || $elem =~ /<s>/ || $elem =~ /<\/s>/){
                    next;
                }else{
                    print STDERR "File format is wrong.\n";
                    print STDERR $line_con."\n";
                    exit(1);
                }
                $body .= $elem;
            }
            for(my $i=0; $i < scalar(@pos) - $XX_count; $i++){
                if($body ne ""){
                    $body .= " ";
                }
                $body .= "(".$pos[$XX_count+$i]." ".$tok[$XX_count+$i].")";
            }
            while($left_bracket_count > $right_bracket_count){
                $body .= " )";
                $left_bracket_count--;
            }
            while($left_bracket_count < $right_bracket_count){
                $body = "(DUMMY ".$body;
                $right_bracket_count--;
            }
            print STDERR "Too little XX. $body \n";
            #print $out_fp "\n";
            print $out_fp "$body\n";
        }elsif(scalar(@pos) < $XX_count){
            print STDERR "Too many XX.\n";
            my $XX_count_local = 0;
            my $skip_count = 0;;
            my $body = "";
            $left_bracket_count = 0;
            $right_bracket_count = 0;
            for my $elem (@con){
                if($elem eq "XX" || $elem eq "." || $elem eq "," || $elem eq ":" || $elem eq "(" || $elem eq ")" || $elem eq "''" || $elem eq "``" || $elem =~/^_/){
                    if($XX_count_local < scalar(@pos)){
                        $elem = "(".$pos[$XX_count_local]." ".$tok[$XX_count_local].")";
                        if($body ne ""){
                            $elem = " ".$elem;
                        }
                        $XX_count_local++;
                    }else{
                        next;
                    }
                }elsif($elem =~ /\)/){
                    my @col = split(/_/, $elem);
                    if($skip_count == 0){
                        $elem = $col[0];
                        $right_bracket_count++;
                    }else{
                        $skip_count--;
                        next;
                    }
                }elsif($elem =~ /\(/){
                    if($XX_count_local < scalar(@pos)){
                        if($body ne ""){
                            $elem = " ".$elem;
                        }
                        $left_bracket_count++;
                    }else{
                        $skip_count++;
                        next;
                    }
            	}elsif($elem =~ /<unk>/ || $elem =~ /<s>/ || $elem =~ /<\/s>/){
                    next;
                }else{
                    print STDERR "File format is wrong.\n";
                    print STDERR $line_con."\n";
                    exit(1);
                }
                $body .= $elem;
            }
            while($left_bracket_count > $right_bracket_count){
                $body .= ")";
                $left_bracket_count--;
            }
            while($left_bracket_count < $right_bracket_count){
                $body = "(DUMMY ".$body;
                $right_bracket_count--;
            }
            print STDERR "Too many XX. $body \n";
            #print $out_fp "\n";
            print $out_fp "$body\n";
        }elsif($left_bracket_count > $right_bracket_count){
            print STDERR "Too many left bracket.\n";
            my $body = "";
            my $XX_count_local = 0;
            for my $elem (@con){
                if($elem eq "XX" || $elem eq "." || $elem eq "," || $elem eq ":" || $elem eq "(" || $elem eq ")" || $elem eq "''" || $elem eq "``" || $elem =~/^_/){
                    $elem = "(".$pos[$XX_count_local]." ".$tok[$XX_count_local].")";
                    if($body ne ""){
                        $elem = " ".$elem;
                    }
                    $XX_count_local++;
                }elsif($elem =~ /\)/){
                    my @col = split(/_/, $elem);
                    $elem = $col[0];
                }elsif($elem =~ /\(/){
                    if($body ne ""){
                        $elem = " ".$elem;
                    }
            	}elsif($elem =~ /<unk>/ || $elem =~ /<s>/ || $elem =~ /<\/s>/){
                    next;
                }else{
                    print STDERR "File format is wrong.\n";
                    print STDERR $line_con."\n";
                    exit(1);
                }
                $body .= $elem;
            }
            #print STDERR $line_con."\n";
            while($left_bracket_count > $right_bracket_count){
                $body .= ")";
                $right_bracket_count++;
            }
            print $out_fp "$body\n";
        }elsif($left_bracket_count < $right_bracket_count){
            print STDERR "Too many right bracket.\n";
            #print STDERR $line_con."\n";
            my $body = "";
            my $XX_count_local = 0;
            for my $elem (@con){
                if($elem eq "XX" || $elem eq "." || $elem eq "," || $elem eq ":" || $elem eq "(" || $elem eq ")" || $elem eq "''" || $elem eq "``" || $elem =~/^_/){
                    $elem = "(".$pos[$XX_count_local]." ".$tok[$XX_count_local].")";
                    if($body ne ""){
                        $elem = " ".$elem;
                    }
                    $XX_count_local++;
                }elsif($elem =~ /\)/){
                    my @col = split(/_/, $elem);
                    $elem = $col[0];
                }elsif($elem =~ /\(/){
                    if($body ne ""){
                        $elem = " ".$elem;
                    }
            	}elsif($elem =~ /<unk>/ || $elem =~ /<s>/ || $elem =~ /<\/s>/){
                    next;
                }else{
                    print STDERR "File format is wrong.\n";
                    print STDERR $line_con."\n";
                    exit(1);
                }
                $body .= $elem;
            }
            while($left_bracket_count < $right_bracket_count){
                $body = "(DUMMY ".$body;
                $right_bracket_count--;
            }
            print $out_fp "$body\n";
        }else{
            my $body = "";
            my $XX_count_local = 0;
            for my $elem (@con){
                if($elem eq "XX" || $elem eq "." || $elem eq "," || $elem eq ":" || $elem eq "(" || $elem eq ")" || $elem eq "''" || $elem eq "``" || $elem =~/^_/){
                    $elem = "(".$pos[$XX_count_local]." ".$tok[$XX_count_local].")";
                    if($body ne ""){
                        $elem = " ".$elem;
                    }
                    $XX_count_local++;
                }elsif($elem =~ /\)/){
                    my @col = split(/_/, $elem);
                    $elem = $col[0];
                }elsif($elem =~ /\(/){
                    if($body ne ""){
                        $elem = " ".$elem;
                    }
            	}elsif($elem =~ /<unk>/ || $elem =~ /<s>/ || $elem =~ /<\/s>/){
                    next;
                }else{
                    print STDERR "File format is wrong.\n";
                    print STDERR $line_con."\n";
                    exit(1);
                }
                $body .= $elem;
            }
            print $out_fp $body."\n";
        }
    }
    close($tok_fp);
    close($pos_fp);
    close($con_fp);
    close($out_fp);
}
