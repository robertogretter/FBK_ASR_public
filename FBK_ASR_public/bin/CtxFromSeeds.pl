#!/usr/bin/perl

# ./CtxFromSeeds.pl -dic /data/disk1/data/kore/gretter/SmarTerpData/LexCovItVanilla4-80K/GLOD128K.oov.orig.lst -ctxw 10 < /data/disk1/data/kore/gretter/SmarTerpData/LexCovItVanilla4-80K/GLOD128K.mrph_mS20_tD2_mmL5.wiki.txt

$dic="";
$ctxw=5;
$debug=1;

for($i=0;$i<=$#ARGV;$i++){
    if($ARGV[$i] eq "-dic"){ # seed words to consider
	$dic=$ARGV[++$i];
    }
    elsif ($ARGV[$i] eq "-ctxw"){ # number of neighbor words to keep
	$ctxw=$ARGV[++$i];
    }
    elsif ($ARGV[$i] eq "-debug"){
	$debug=$ARGV[++$i];
    }
    elsif (($ARGV[$i] eq "-help") || ($ARGV[$i] eq "-h")){
	usage("");
    }
    else{
	usage("unknown option ".$ARGV[$i]);
    }
}

printf STDERR "dic: %s\nctxw: %d\n",$dic,$ctxw
    if($debug >=1);

$dicsize=0;

open(D, "<$dic") || die "cannot read dic file $dic.";
while($line=<D>){
    $line=~s/\r?\n//; # bastardo dos
    if($line=~m/([\S]+)/){
	$wrd=$1;
	$dicsize++;
	$seeds{$wrd}=1;
    }
    else{
	print STDERR "discard line <$line>\n"
	    if($debug >=1);
    }
}
close(D);
printf STDERR "read %d seed words from %s\n", $dicsize,$dic
    if($debug >=1);
if($debug >=2){
    foreach $s (keys %seeds){ printf STDERR " %s ",$s; } printf STDERR "\n\n";
}

$rw=0;  # input running words 
$rws=0; # seed running words
$rwc=0; # ctx running words
$pc="%";

while($line=<STDIN>){
    $line=~s/\r?\n//; # bastardo dos
    $line=~s=<\/?s>==g;
    $line=~s/^\s+|\s+$//g;
    
    $line=~s/\s+/ /g;
    @ow=();  # original words
    @ow=split(/\s+/, $line);
    @w2k=(); # words to keep
    @ss=(); # seed indices
    $rw+=($#ow+1); # number of running words
    printf STDERR "%d %d %s\n", $rw,$#ow+1,$line
	if($debug >=2);
    for($i=0;$i<=$#ow;$i++){
	$w=@ow[$i];
	$w2k[$i]=0;
	$s=defined($seeds{$w}) ? 1 : 0;
	if($s){
	    $rws++; # seed running words
	    push @ss, $i;
	    printf STDERR "SEED %s %d\n",$w,$i
		if($debug >=2);
	}
    }
    if($#ss>=0){
	if($debug >=2){
	    printf STDERR "Seed Indices:";
	    for($i=0;$i<=$#ss;$i++){printf STDERR " %d",$ss[$i];}
	    printf STDERR "\n";
	}
	for($i=0;$i<=$#ss;$i++){
	    $w2k[$ss[$i]]+=3;
	    for($j=max(0,$ss[$i]-$ctxw);$j<=min($ss[$i]+$ctxw,$#ow);$j++){
		$w2k[$j]++;
	    }
	}
	if($debug >=2){
	    printf STDERR "Seed Word Mask (%d words):",$#ow+1;
	    for($i=0;$i<=$#ow;$i++){printf STDERR " %d",$w2k[$i];}
	    printf STDERR "\n";
	}
	$out="";
	for($i=0;$i<=$#ow;$i++){
	    if($w2k[$i]>=1){
		$out.=" ".$ow[$i];
		$rwc++;
	    }
	}
	print "$out \n"
	    if($out=~m/\S/);
	print STDERR "$out \n\n"
	    if($debug >=2);
    }

}

printf STDERR "read %d running words from stdin ; found %d seeds, kept %d words (%.2f%s)\n",
    $rw, $rws, $rwc, 100*$rwc/$rw,$pc
    if($debug >=1);

sub min()
{
    local($a,$b)=@_;
    return $a
	if($a<=$b);
    return $b;
}

sub max()
{
    local($a,$b)=@_;
    return $a
	if($a>=$b);
    return $b;
}


sub usage()
{
    local($ss)=@_;
    print STDERR "\nUsage: $0 [options] < text > text_ctx_seeds\n\n";
    print STDERR "Keep a fixed context with regards to seed words; [options] are:\n";
    print STDERR "\t-dic DIC    : DICTIONARY to load, each line has one SEED WORD\n";
    print STDERR "\t-ctxw CTXW  : length of context to keep, in words\n";
    print STDERR "\t-debug D    : D can be 0, 1, 2 (default 1)\n";
    print STDERR "\t-h | -help  : print this message and exit\n";
    print STDERR "\n$ss\n\n";
    exit(1);
}



# run:
# date
# ddd=/data/disk1/data/kore/gretter/SmarTerpData/ItalianV3
# zcat $ddd/*.nopunct.gz | \
#     ./ReplaceRareWordsWithUnk.pl -dict $ddd/tutto.dict -mincnt 10 -debug 1 | gzip -c > asda10.gz 
# date

# output:
# Wed Apr 28 13:30:10 CEST 2021
# dict: /data/disk1/data/kore/gretter/SmarTerpData/ItalianV3/tutto.dict
# mincnt: 10
# unk: <unk>
# discard line <DICTIONARY 0 4943488>
# read 4943488 words from /data/disk1/data/kore/gretter/SmarTerpData/ItalianV3/tutto.dict ; mincnt 10 ; kept 848088 (17.16%), left 4095400 (82.84%)
# read 3269051522 running words from stdin ; known 3259846111 (99.72%), rare 9205411 (0.28%), unknown 0 (0.00%) (sum 3269051522)
# Wed Apr 28 16:17:10 CEST 2021
# ~/bin/tdiff 13:30:10 16:17:10                ->           16:17:10 - 13:30:10 = 02:47:00
# du -sh asda10.gz                             ->           5.5G	asda10.gz



