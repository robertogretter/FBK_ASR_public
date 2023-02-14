#!/usr/bin/perl

# Roberto Gretter, FBK, 2020 - 2021 

# ./TLT2021EvalScript.pl -ref ENREF -test ENTST -d 0
# WER=  65.49% (S=   36 I=   19 D=   19) / REFERENCE_WORDS=  113 - UTTERANCES=   10 
# ./TLT2021EvalScript.pl -ref DEREF -test DETST -d 0
# WER=  38.46% (S=    0 I=   13 D=    2) / REFERENCE_WORDS=   39 - UTTERANCES=   10

# perl version v5.26.1 does not accept encoding pragma anymore
#use encoding (utf8);
#binmode stdin,  ":utf8";
#binmode stdout, ":utf8";
#binmode stderr, ":utf8";

$debug=0;
$sep="_";
$keepminus=0;

for($i=0;$i<=$#ARGV;$i++){
    if($ARGV[$i] eq "-ref"){
	$ref=$ARGV[++$i]; # reference
    }
    elsif($ARGV[$i] eq "-test"){
	$tst=$ARGV[++$i]; # recognition (test)
    }
    elsif($ARGV[$i] eq "-sep"){ # separator
	$sep=$ARGV[++$i];
    }
    elsif($ARGV[$i] eq "-keepminus"){ # separator
	$keepminus=$ARGV[++$i];
    }
    elsif($ARGV[$i] eq "-d"){ # debug level
	$debug=$ARGV[++$i];
    }
    elsif($ARGV[$i] eq "-h" || $ARGV[$i] eq "-help"){ # help
	usage("");
    }
    else{
	usage("wrong usage, unknown option $i <$ARGV[$i]>");
    }
}

open (RR, "<$ref") || usage("cannot open REF_FILE <$ref>");
open (TT, "<$tst") || usage("cannot open TEST_FILE <$tst>");

$lc=0;
$terrs=$tsubs=$tins=$tdel=$treflen=0;
while($refline=<RR>){
    $tstline=<TT>;
    $lc++;
    $refline=~s/\r?\n//; # bastardo dos
    $tstline=~s/\r?\n//; # bastardo dos
    $refline=~s/\s+/ /g;
    $tstline=~s/\s+/ /g;
    $refline=" ".$refline." ";
    $tstline=" ".$tstline." ";

    # utterance id check
    if($refline=~s/^\s*(\S+)//){$refid=$1;}else{die "cannot parse line $lc of REF file $ref\n<$refline>";}
    if($tstline=~s/^\s*(\S+)//){$tstid=$1;}else{die "cannot parse line $lc of TEST file $tst\n<$tstline>";}
    if($refid ne $tstid){die "REF id and TEST id differ, line $lc: <$refid> vs <$tstid>";}

    if($debug>=2){
	print "RefId $refid OriginalRef  <$refline>\n";
	print "TstId $tstid OriginalTst  <$tstline>\n";
    }

    # reference string normalization
    while($refline=~s/\@it\([^\)]+\)/ /){}
    while($refline=~s/\@de\([^\)]+\)/ /){}
    while($refline=~s/\@en\([^\)]+\)/ /){} # added for german data, RG Feb 2021
    while($refline=~s/\@unk\([^\)]+\)/ /){}
    $refline=~s/<unk>/ /g;
    $refline=~s/<unk-it>/ /g;
    $refline=~s/<unk-de>/ /g;
    $refline=~s/<unk-en>/ /g;
    if($keepminus){
	while($refline=~s/ [a-z']+\- / /){}
	while($refline=~s/ \-[a-z']+ / /){}
    }
    else{
	while($refline=~s/ ([a-z']+)\- / $1 /){}
	while($refline=~s/ \-([a-z']+) / $1 /){}
    }
    $refline=~s/@[a-z]+/ /g;
    while($refline=~s/ \- / /){}
    $refline=~s/[\(\#\*\@\)]+/ /g;

    # test string normalization
    while($tstline=~s/ [a-z']+\- / /){}
    while($tstline=~s/ \-[a-z']+ / /){}
    while($tstline=~s/ \- / /){}
    $tstline=~s/@[a-z]+/ /g;
    $tstline=~s/<unk>/ /g;
    $tstline=~s/<unk-it>/ /g;
    $tstline=~s/<unk-de>/ /g;
    $tstline=~s/<unk-en>/ /g;
    $tstline=~s/ de_\S+/ /g;
    $tstline=~s/ en_\S+/ /g;
    $tstline=~s/ it_\S+/ /g;
    

    $refline=~s/\s+/ /g;
    $tstline=~s/\s+/ /g;
    $refline=~s/^\s+|\s+$//g;
    $tstline=~s/^\s+|\s+$//g;

    if($debug>=1){
	print "RefId $refid ProcessedRef <$refline>\n";
	print "TstId $tstid ProcessedTst <$tstline>\n";
    }
    
    # edit distance computation
    $ld=LevDistance($refline,$tstline,$debug);

    # WER computation
    $ld=~m/ERRS ([0-9]+) S ([0-9]+) I ([0-9]+) D ([0-9]+) REF ([0-9]+) /;
    ($errs,$subs,$ins,$del,$reflen)=($1,$2,$3,$4,$5);
    $ref=
    $terrs+=$errs;
    $tsubs+=$subs;
    $tins+=$ins;
    $tdel+=$del;
    $treflen+=$reflen;
    $wer= ($reflen  >= 1) ? (100.0*($subs  + $ins  + $del)  / $reflen  ) : 100.0;
    $twer=($treflen >= 1) ? (100.0*($tsubs + $tins + $tdel) / $treflen ) : 100.0;
    if($debug>=1){
	printf "line %4d - %-30s - ",$lc,$ld;
	printf "LOCAL WER %6.2f\% - (S= %2d I= %2d D= %2d) / REF= %3d - ",  $wer,  $subs,  $ins,  $del,  $reflen;
	printf "GLOBAL WER %6.2f\% - (S= %4d I= %4d D= %4d) / REF= %5d - UTT= %4d ", $twer, $tsubs, $tins, $tdel, $treflen, $lc;
	printf "\n\n";
    }
}

# final WER
printf "WER= %6.2f\% (S= %4d I= %4d D= %4d) / REFERENCE_WORDS= %4d - UTTERANCES= %4d \n", 
    $twer, $tsubs, $tins, $tdel, $treflen, $lc;

close(RR);
close(TT);

exit(0);

sub LevDistance()
{
    local($a,$b,$deb)=@_;
    local($i,$j,$d,$laa,$m,$m1,$m2,$m3,@aa,@bb,@dist,@bckp,@errs);
    local($errs,$subs,$ins,$del);

    @aa=split(/\s+/,"- ".$a);
    @bb=split(/\s+/,"- ".$b);
    $d=0; # $d=$#aa-$#bb; if($d<0){$d=-$d;}
    
    if($deb>=2){
	print "Ref  --> ";
	for($i=0;$i<=$#aa;$i++){ print "$aa[$i] "; }
	print "\n";
	print "Test --> ";
	for($j=0;$j<=$#bb;$j++){ print "$bb[$j] "; }
	print "\n";
    }

    $laa=$#aa+1;
    
    # forward computation
    for($i=0;$i<=$#aa;$i++){ @dist[$i + 0     ]=$i+$d; @bckp[$i + 0]="|";      @errs[$i + 0]="D$sep$aa[$i]"; }
    for($j=1;$j<=$#bb;$j++){ @dist[0 + $j*$laa]=$j+$d; @bckp[0 + $j*$laa]="_"; @errs[0 + $j*$laa]="I$sep$bb[$j]"; }
    @errs[0]="OK <start>"; 
    @bckp[0]="\\";
    for($i=1;$i<=$#aa;$i++){
	for($j=1;$j<=$#bb;$j++){
	    $m=($aa[$i] eq $bb[$j]) ? 0 : 1;
	    $m1=@dist[($i-1) + ($j-1)*$laa]+$m;
	    $m2=@dist[($i)   + ($j-1)*$laa]+1;
	    $m3=@dist[($i-1) + ($j  )*$laa]+1;
	    
	    @dist[$i + $j*$laa]= $m1<$m2 ? ($m1<$m3 ? $m1 :$m3) : ($m2<$m3 ? $m2:$m3);
	    @bckp[$i + $j*$laa]= $m1<$m2 ? ($m1<$m3 ? "\\":"|") : ($m2<$m3 ? "_":"|");
	    @errs[$i + $j*$laa]= $m1<$m2 ? ($m1<$m3 ? ($m == 0 ? "OK$sep$aa[$i]" : "S$sep$aa[$i]$sep$bb[$j]" ) : "D$sep$aa[$i]") : ($m2<$m3 ? "I$sep$bb[$j]":"D$sep$aa[$i]");
	}
    }

    # backtracking
    $errs=$subs=$ins=$del=0;
    $i=$#aa;$j=$#bb;
    local(@trace)=();
    while(($i+$j)>=0){
	# @errs[$i + $j*$laa]="*".@errs[$i + $j*$laa];
	push(@trace,@errs[$i + $j*$laa]);
	if(@bckp[$i + $j*$laa] eq "\\"){
	    if(@errs[$i + $j*$laa]=~m/^S/){$subs++; $errs++;}
	    $i--;$j--;
	}
	elsif(@bckp[$i + $j*$laa] eq "|"){
	    $del++; $errs++; # corrected, was ins
	    $i--;
	}
	elsif(@bckp[$i + $j*$laa] eq "_"){
	    $ins++; $errs++; # corrected, was del
	    $j--;
	}
    }

    # total distance
    $d=@dist[$#aa + $#bb*$laa];

    # just debug info

    $error="";
    for($i=$#trace;$i>=0;$i--){
	$error.=" ".$#trace - $i." ".$trace[$i]." "
	    unless($trace[$i]=~/^OK/);
    }
    # printing standard trellis
    if($deb>=3){
	printf "\n%3s ","r\\t"; 
	for($j=0;$j<=$#bb;$j++){
	    printf " %10s",$bb[$j];
	}
	printf "\n";
	for($i=0;$i<=$#aa;$i++){
	    printf "%10s  ",$aa[$i];
	    for($j=0;$j<=$#bb;$j++){
		printf "%1s%2d        ", @bckp[$i + $j*$laa], @dist[$i + $j*$laa];
	    }
	    printf "\n";
	}
	print " distance $d - errs $errs S $subs I $ins D $del\n"; # @dist[$#aa + $#bb*$laa]
    }
    # printing some more informative trellis
    if($deb>=4){
	printf "\n%3s ","r\\t"; 
	for($j=0;$j<=$#bb;$j++){
	    printf " %10s %13s",$bb[$j],"";
	}
	printf "\n";
	for($i=0;$i<=$#aa;$i++){
	    printf "%10s  ",$aa[$i];
	    for($j=0;$j<=$#bb;$j++){
		printf "%1s%2d %-20s ", @bckp[$i + $j*$laa], @dist[$i + $j*$laa], @errs[$i + $j*$laa];
	    }
	    printf "\n";
	}
    }
    # printing just best path
    if($deb>=2){
	while($i=pop(@trace)){
	    printf "trace %s\n",$i
		unless($i=~m/OK <start>/);
	}
    }
    
    $error=~s/\s+/ /g;
    print "DISTANCE $d ERROR <$error>\n"
	if($deb>=1);
    print "\n"
	if($deb>=2);

    $out="ERRS $errs S $subs I $ins D $del REF $#aa ";
    return $out;
}

sub usage()
{
    local($s)=@_;
    
    printf STDERR "\n\n usage: \n%s -ref REF_FILE -test TEST_FILE [options]\n",$0;
    printf STDERR " where:\n";
    printf STDERR "  -ref REF_FILE    # ref file, on each line: SentId RefW1 RefW2 ... RefWn \n";
    printf STDERR "  -test TEST_FILE  # test file, on each line: SentId RecW1 RecW2 ... RecWm \n";
    printf STDERR "  -d DEBUG         # debug level, default 0, max 4\n";
    printf STDERR "  -sep SEP         # separator for trace pattern, default _\n";
    printf STDERR "  -h|-help         # shows this output\n\n";
    
    printf STDERR " returns Word Error Rate, computed as 100*(S+I+D)/REF_LENGTH;\n";
    printf STDERR " some normalizations are done on ref and test strings before matching;\n";
    printf STDERR " REF_FILE and TEST_FILE must be aligned (via sort).\n\n\n";
    
    printf STDERR "%s\n\n", $s
	if ($s=~m/\S/);
    exit(1);
}

