#!/bin/sh

ref=$1
blm=$2
dic=$3
options="$4 $5 $6" # -nonum --> numbers in digits are supposed to be known

. ./here.sh

perloov()
{
    dic=$1 # dic
    perl -e ' # binmode stdin, ":utf8";binmode stdout, ":utf8";
    %dd=();
    $c=0;$normalize=0;$numbersknown=0;$truncatedknown=0;
    open(D, "$ARGV[0]") || die "cannot read dic file $ARGV[0]";
    for($i=1;$i<=$#ARGV;$i++){
     if($ARGV[$i] eq "-norm"){$normalize=1;}
     if($ARGV[$i] eq "-nonum"){$numbersknown=1;}
     if($ARGV[$i] eq "-notrunc"){$truncatedknown=1;}
    }
    # binmode D, ":utf8";
    while($l=<D>){
        $l=~s/\r?\n//; # bastardo dos
	if($normalize == 1){$l=~tr/A-Z/a-z/;}
	if($l=~m/(\S+)/){$dd{$1}=1;$c++;}
	else{print "WARNING: cannot parse dic line <$l>\n";}
    }
    close(D);
    printf "read %d words from dic %s.\n",$c,$ARGV[0];
    $rw=0; # number of running words
    $rkn=0; # number of known running words
    $runkn=0; # number of unknown running words
    $dunkn=0; # number of different unknown words
    %new=();
    while($ll=<STDIN>){
      $ll=~s/\r?\n//; # bastardo dos
      # printf "line>> %s <<\n",$ll;
      @ww=split(/\s+/,$ll);
      foreach $w (@ww){
	if($normalize == 1){$w=~tr/A-Z/a-z/;}
	if(($w=~m/\S/) && ($w ne "<s>") && ($w ne "</s>")){
	  $rw++; # printf "%s %d - %d\n",$w, $dd{$w}, $rw;
	  if(($numbersknown == 1) && ($w=~m/^[0-9]+$/)){
	    $rkn++;
	  }
	  elsif( ($truncatedknown == 1) && ( ($w=~m/^\-/) || ($w=~m/\-$/) ) ){
	    $rkn++;
	  }
	  elsif(defined($dd{$w})){
	    $rkn++;
	  }
	  else{
	    $runkn++;
	    if(defined($new{$w})){
	      $new{$w}++;   printf " %s unknown %s time\n",$w,$new{$w};
	    }
	    else{
	      $dunkn++;  printf " %s unknown first time\n",$w;
	      $new{$w}=1;
	    }
	  }
	}
      }
    }
    printf "%5d run_wrds ; %5d known_wrds ; %5d (%5.2f\%) oov_wrds (rate) ; %5d oov diff words ; ", $rw, $rkn, $runkn, 100*$runkn/$rw, $dunkn;
    ' $dic $options
}

# lo trova in here.sh
# COMPILELM=/data/disk1/data/kore/gretter/irstlm-20110801/bin/compile-lm

cat $ref | perloov $dic 
echo;echo

oov=`cat $ref | perloov $dic | grep -v "words from dic" | grep -v unknown`

# if [ $blm != "none" ]
if [ "$blm" = "none" ]
then echo REF= $ref
     echo DIC= $dic
     echo OOV= $oov 
else ppp=`$COMPILELM -e $ref $blm | grep "%%"`
     echo REF= $ref
     echo BLM= $blm
     echo DIC= $dic
     echo PPP= $ppp
     echo OOV= $oov 
fi


