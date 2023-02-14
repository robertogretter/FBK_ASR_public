#!/usr/bin/perl

# WordCtm2PhraseCtm.pl -s 0.3 -d 1 < word.ctm >phrase.ctm

# per splittare su silenzi un pctm in frasi da max un minuto
#	awk 'BEGIN{sta=0.0;le=0.0}
#             {lb=$1;end=$3+$4;if((end-sta)>60){ns=(le+$3)/2;printf "%s %.3f %.3f\n",lb,sta,ns; sta=ns;}le=end}
#              END{printf "%s %.3f %.3f\n",lb,sta,end;}' $ctm.pctm


# cat It3/BadBlood_101_ita_16k.ref.ctm | ~/bin/WordCtm2PhraseCtm.pl -d 0 -s 0.1 | awk '{print $3,$0}' > asd1

$debug=0;
$osil=0.3;  # duration to close a phrase - original
$sil=$osil; # duration to close a phrase - working
$whs=1000;  # words to halve sil
$times=0;   # if 1, keep times

for($i=0;$i<=$#ARGV;$i++){
    if ($ARGV[$i] eq "-d"){
        $debug=$ARGV[++$i];
    }
    elsif ($ARGV[$i] eq "-s"){
	$osil=$ARGV[++$i];
        $sil=$osil;
    }
    elsif ($ARGV[$i] eq "-whs"){
        $whs=$ARGV[++$i];
    }
    elsif ($ARGV[$i] eq "-t"){
        $times=1;
    }
    else{
	printf STDERR "\n$0 options < word.ctm > phrase.ctm\n";
	printf STDERR "transforms a ctm of words into a ctm of phrases, using pauses; options are:\n";
	printf STDERR " -d debug    # to get more information about the processing\n";
	printf STDERR " -s duration # duration of silence needed to split phrases\n";
	printf STDERR " -whs n      # number of words to relax sil requirements\n";
	printf STDERR " -t          # keep times between words\n";
        die "\nwrong option $ARGV[$i].";
    }
}

$lid="";
$begin=-1.0;
$end=-1.0;
$wrds="";
$nwrds=0;
$i=0;

while($r=<STDIN>){
    $i++;
    $r=~s/\r?\n//; #bastardo dos
    print "$r\n" 
	if($debug>=1);
    # BadBlood_101_ita_16k 1 39.235 0.040 e
    if($r=~m/(\S+)\s+(\S+)\s+([0-9\.]+)\s+([0-9\.]+)\s+(\S+)\s*/){
	($id,$l,$b,$d,$wrd)=($1,$2,$3,$4,$5);

	if($lid ne $id){
	    flush("lastid different")
		if($wrds=~m/\S/);
	}

	if($begin < 0.0){ # start of new phrase, maybe
	    if($wrd ne "\@bg"){
		$begin=$b; $end=$b+$d;
		$wrds=$wrds."+==".$begin."==+ " if($times);
		$wrds=$wrds.$wrd." ";
		$nwrds++;if($nwrds>$whs){$sil=$osil/2;}if($nwrds>($whs*2)){$sil=$osil/4;}
		$wrds=$wrds."+=".$end."=+ " if($times);
	    }
	}
	else{ # phrase already started
	    if(($wrd eq "\@bg") && ($d >= $sil)){ # phrase ends
		flush("found long \@bg")
		    if($wrds=~m/\S/);
	    }
	    else{ # phrase continue
		if(($b-$end) >= $sil){ # big hole
		    flush("big hole")
			if($wrds=~m/\S/);
		    if($wrd ne "\@bg"){
			$begin=$b; $end=$b+$d; 
			$wrds=$wrds."+==".$begin."==+ " if($times);
			$wrds=$wrds.$wrd." ";
			$nwrds++;if($nwrds>$whs){$sil=$osil/2;}if($nwrds>($whs*2)){$sil=$osil/4;}
			$wrds=$wrds."+=".$end."=+ " if($times);
		    }
		}
		else{
		    if($wrd ne "\@bg"){
			$end=$b+$d; $wrds=$wrds.$wrd." ";
			$nwrds++;if($nwrds>$whs){$sil=$osil/2;}if($nwrds>($whs*2)){$sil=$osil/4;}
			$wrds=$wrds."+=".$end."=+ " if($times);
		    }
		}
	    }
	}
	$lid=$id;
	$ll=$l;
    }
}
flush("ctm end");

sub flush()
{
    local($s)=@_;
    $dur=$end-$begin;
    if($dur >= 0){
	printf "%s %s %.3f %.3f %s %s\n",$lid, $ll, $begin, $dur, $wrds, (($debug>=1)?"[".$i." ".$end." ".$s."]":"");
    }
    $begin=-1.0;
    $end=-1.0;
    $wrds="";
    $nwrds=0;
    $sil=$osil;
}

