use utf8;
use strict;
binmode STDIN,":utf8";
binmode STDOUT,":utf8";
binmode STDERR,":utf8";

&main();

sub main {
    my $constituency_path = $ARGV[0];
    my $dependency_path = $ARGV[1];
    my $output_constituency_path = $ARGV[2];
    my $output_alignment_path =$ARGV[3];
    open(my $const_fp, "$constituency_path");
    open(my $dep_fp, "$dependency_path");
    open(my $out_const_fp, ">$output_constituency_path");
    open(my $out_align_fp, ">$output_alignment_path");
    while(1){
        my @const = &string_to_internal($const_fp);
        #my @dep = &conllu_to_internal($dep_fp);
        my @dep = &yamada_to_internal($dep_fp);
        my @aligned = &head_search(\@const, \@dep);
        my @aligned_norm = &pos_norm(\@aligned);
        &output_to_files($out_const_fp,$out_align_fp,\@aligned_norm);
    }
    close($const_fp);
    close($dep_fp);
    close($out_const_fp);
    close($out_align_fp);
}

sub output_to_files {
    my ($out_const_fp,$out_align_fp,$aligned) = (@_);
    my $line_const = "";
    my $line_align = "";
    my @align = ();
    for(my $i=0;$i < scalar(@$aligned);$i++){
        if($line_const ne ""){
            $line_const .= " ";
        }
        if($$aligned[$i][0] =~ /\)/){
            $line_const .= $$aligned[$i][0]."_".$$aligned[$i][3];
        }else{
            $line_const .= $$aligned[$i][0];
        }
        push(@align, ([$$aligned[$i][5], $i]));
    }
    foreach my $elem (sort { @$a[0] <=> @$b[0] } @align){
        if($line_align ne ""){
            $line_align .= " ";
        }
        $line_align .= $$elem[0]."-".$$elem[1];
    }
    print $out_const_fp $line_const."\n";
    print $out_align_fp $line_align."\n";
}

sub pos_norm {
    my ($aligned) = (@_);
    my @aligned_norm = ();
    for(my $i=0; $i < scalar(@$aligned); $i++){
        if($$aligned[$i][4] == 1){
            if($$aligned[$i][0] =~ /\(/){
                next;
            }else{
                my $p = $$aligned[$i][3];
                if($p ne "." && $p ne "," && $p ne ":" && $p ne "(" && $p ne ")" && $p ne "''" && $p ne "``"){
                    push(@aligned_norm, (['XX',$$aligned[$i][1],$$aligned[$i][2],'XX',$$aligned[$i][4],$$aligned[$i][5]]));
                }else{
                    push(@aligned_norm, ([$p,$$aligned[$i][1],$$aligned[$i][2],$p,$$aligned[$i][4],$$aligned[$i][5]]));
                }
            }
        }else{
            push(@aligned_norm, ([$$aligned[$i][0],$$aligned[$i][1],$$aligned[$i][2],$$aligned[$i][3],$$aligned[$i][4],$$aligned[$i][5]]));
        }
    }
=comment
    # test
    for(my $i=0;$i < scalar(@aligned_norm);$i++){
        print $aligned_norm[$i][0]."_".$aligned_norm[$i][1]."_".$aligned_norm[$i][2]."_".$aligned_norm[$i][4]." ";
    }
    print "\n";
=cut
    return @aligned_norm;
}

sub head_search {
    my ($const, $dep) = (@_);
    my @aligned = ();
    for(my $i=0; $i < scalar(@$const); $i++){
        for(my $j = $$const[$i][1]; $j <= $$const[$i][2]; $j++){
            if($$dep[$j] < $$const[$i][1] || $$const[$i][2] < $$dep[$j]){
                push(@aligned, ([$$const[$i][0],$$const[$i][1],$$const[$i][2],$$const[$i][3],$$const[$i][4],$j]));
                #print $i."\t".$$const[$i][1]."\t".$$const[$i][2]."\t".$$dep[$j]."\n";
            }
        }
    }
    if(scalar(@$const) != scalar(@aligned)){
        print "size does not match.";
        exit(1);
    }
=comment
    # test
    for(my $i=0;$i < scalar(@aligned);$i++){
        print $aligned[$i][0]."_".$aligned[$i][1]."_".$aligned[$i][2]."_".$aligned[$i][4]." ";
    }
    print "\n";
=cut
    return @aligned;
}

sub yamada_to_internal {
    my ($dep_fp) = (@_);
    my @dep = ();
    while(my $line = <$dep_fp>){
        chomp($line);
        if($line eq ""){
           last;
        }
        my @col = split(/\t/, $line);
        if(scalar(@col) == 3){
            push(@dep, $col[2] - 1);
        }
    }
=comment
    for(my $i=0;$i<scalar(@dep);$i++){
        print $i."\t".$dep[$i]."\n";
    }
=cut
    return @dep;
}

sub conllu_to_internal {
    my ($dep_fp) = (@_);
    my @dep = ();
    while(my $line = <$dep_fp>){
        chomp($line);
        if($line eq ""){
           last;
        }
        my @col = split(/\t/, $line);
        push(@dep, ($col[6] - 1));
    }
    return @dep;
}

sub string_to_internal {
    my ($out_align_fp) = (@_);
    my $line = <$out_align_fp>;
    chomp($line);
    #print $line."\n";
    if(!$line){
        print STDERR "Conversion is correctly finished.\n";
        exit(0);
    }
    $line =~ s/\(/ (/g;
    $line =~ s/\)/) /g;
    $line =~ s/^ *(.*?) *$/$1/;
    $line =~ s/ +/ /g;
    my @sequence = split(/ /, $line);
    my @stack = ();
    my @output = ();
    my $leaf_index = -1;
    my $prev = '';
    my $current_start = 0;
    for my $str (@sequence){
        if($str =~ /^\(/){
            my $label = $str;
            $label =~ s/\(//g;
            # string, start_index, end_index, label, is_leaf
            push(@stack, ([$str,-1,-1,$label,0]));
            push(@output,([$str,-1,-1,$label,0]));
            $prev = '(';
        }elsif($str =~ /\)$/){
            my $is_leaf = 0;
            if($prev eq '('){ # case of a leaf node
               $leaf_index++;
               $is_leaf = 1;
               for(my $i=0; $i < scalar(@stack); $i++){
                   if($stack[$i][1] == -1){
                       $stack[$i][1] = $leaf_index;
                   }
               }
            }
            push(@output, ([$str,$stack[$#stack][1],$leaf_index,$stack[$#stack][3],$is_leaf]));
            for(my $i = $#output; $i >= 0; $i--){
                if($output[$i][1] == -1 && $output[$i][2] == -1){
                    $output[$i] = ([$output[$i][0], $output[$#output][1], $output[$#output][2], $output[$#output][3], $output[$#output][4]]);
                    last;
                }
            }
            pop(@stack);
            $prev = ')';
        }
    }
=comment
    # test
    for(my $i=0;$i < scalar(@output);$i++){
        if($sequence[$i] ne $output[$i][0]){
            print STDERR "Test failed.\n";
            exit(0);
        }
        print $output[$i][0]."_".$output[$i][1]."_".$output[$i][2]."_".$output[$i][4]." ";
    }
    print "\n";
=cut
    return @output;
}
