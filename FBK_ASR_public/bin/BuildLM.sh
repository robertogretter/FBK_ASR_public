#!/bin/sh

. ./here.sh

# costruisce modelli del linguaggio per 5 lingue
# include un file di definizioni

# per ripristinare link a virgo:
# cd /data/disk1/data/kore/gretter/common-voice
# sshfs gretter@virgo:/data/disk1/data/corpora/common-voice/ common-voice-virgo

# uso CleanTextMar2021 con controllo max numero processi!!
# sh BuildLM.sh DeclItalianV2.sh -todo all > report.rep &

# sh BuildLM.sh DeclItalianV2.sh -todo all
# sh BuildLM.sh DeclEnglishV2.sh -todo all
# sh BuildLM.sh DeclSpanishV1.sh -todo all > BuildLM_SpanishV1.rep &
# sh BuildLM.sh DeclEnglishV0.sh -todo all > reportEn.rep &
# sh BuildLM.sh DeclItalianV0.sh -todo all > report.rep &
# sh BuildLM.sh DeclSpanishV0.sh -todo all > report.rep &
# sh BuildLM.sh DeclFrenchV1.sh -todo all > report.rep &
# tail -f report.rep

# ispirato a ../Multilingual3/Hungarian/PrepareHungarianLM.sh

usage()
{
    echo;echo "Usage: $0 DeclFile.sh options";echo
    echo "loads parameters from DeclFile.sh, then updates command line parameters, then executes the defined steps. options are:"
    echo
    echo " -todo string # string defines what to do. possible values of string are:"
    echo "              # all  --> +clean+bldngr+phtrans+bldlm+prunelm+report+eval+cleanup+"
    echo " -h           # prints usage and quit"
    echo " @par=value   # assign 'value' to parameter 'par' - will overwrite definitions in DeclFile.sh"
    echo;echo "$1";echo
    exit
}

header()
{
    rrr="$1"
    date=`date`
    echo "$1 at $date" | awk \
     '{l=length($0); printf "\n\n";
       for(i=1;i<=(l+10);i++){printf("*")}; printf "\n**** %s ****\n",$0;
       for(i=1;i<=(l+10);i++){printf("*")}; printf "\n\n";}'
}

checkpar()
{
    par=$1
    value="$2"
    echo "parameter $par " | awk '{printf "%s %-15s ",$1,$2}'
    echo "value= $value" 
    if [ -z "$value" ]
    then echo "value not defined for parameter $par, exiting"
	 usage "please define parameter $par"
    fi
}

perlwc()
{
    # replace
    # awk 'BEGIN{l=0;w=0;}{l++;w+=NF;}END{print l, w}'
    # awk: program limit exceeded: maximum number of fields size=32767
    # FILENAME="-" FNR=13 NR=13 - ( una linea ha 36925 parole )

    perl -e '
    $l=0;$w=0;
    while($ll=<STDIN>){
	# print $ll;
	$ll=~s/\r?\n//; @ww=split(/\s+/,$ll); $l++; $w+=$#ww;
	# printf "%d %d (%d)\n", $l,$w,$#ww;
    }
    printf "%d %d\n", $l, $w;'
}

perloov() # same in PerlOOV.sh
{
    dic=$1 # dic
    perl -e ' # binmode stdin, ":utf8";binmode stdout, ":utf8";
    %dd=();
    $c=0;
    open(D, "$ARGV[0]") || die "cannot read dic file $ARGV[0]";
    # binmode D, ":utf8";
    while($l=<D>){
        $l=~s/\r?\n//; # bastardo dos
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
	if(($w=~m/\S/) && ($w ne "<s>") && ($w ne "</s>")){
	  $rw++; # printf "%s %d - %d\n",$w, $dd{$w}, $rw;
	  if(defined($dd{$w})){
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
    ' $dic
}

# NGCOUNT=/data/disk1/data/kore/gretter/spinet/mlhmm09/bin/x86_64/ngcount
# DICT=/data/disk1/data/kore/gretter/irstlm-20110801/bin/dict
# TLM=/data/disk1/data/kore/gretter/irstlm-20110801/bin/tlm
# PRUNELM=/data/disk1/data/kore/gretter/irstlm-20110801/bin/prune-lm
# COMPILELM=/data/disk1/data/kore/gretter/irstlm-20110801/bin/compile-lm
# CDICT=/data/disk1/data/kore/gretter/bin/ComponeDict.pl
# RDICT=/data/disk1/data/kore/gretter/bin/ReduceDic.pl

whattodo="nil"
onlyupper2lower=0
header "starting"

if [ -f "$1" ]
then echo loading definitions from Decl file $1
     DeclFile=$1
     . ./$DeclFile
     shift
else echo "cannot find Decl file $1, exiting"
     usage "please specify an existing Decl file"
fi

opts=" "
while [ $# -gt 0 ] ; do
    case "$1" in
	-todo)
	    shift ; whattodo=$1 ;;
	-h)
            usage "" ;;
        @*=*)   _n=`expr "$1" : '.\([^=]*\)='`
                _v=`expr "$1" : '.[^=]*=\(.*\)'`
		opts="$opts $1 "
		eval "$_n='$_v'"
		echo "setting parameter $_n  --> $_v"
		;;
	*)
	    usage "wrong option $1"; 
            break ;;
    esac
    shift
done

if [ "$whattodo" = "all" ]
then wtd="+clean+bldngr+phtrans+bldlm+prunelm+report+eval+cleanup+"
else wtd="+$whattodo+"
fi

clean=`   echo 0$wtd | sed 's/+clean+/1/'   | tr -d "a-z+" | awk '{printf "%d",$1}'`
bldngr=`  echo 0$wtd | sed 's/+bldngr+/1/'  | tr -d "a-z+" | awk '{printf "%d",$1}'`
phtrans=` echo 0$wtd | sed 's/+phtrans+/1/' | tr -d "a-z+" | awk '{printf "%d",$1}'`
bldlm=`   echo 0$wtd | sed 's/+bldlm+/1/'   | tr -d "a-z+" | awk '{printf "%d",$1}'`
prunelm=` echo 0$wtd | sed 's/+prunelm+/1/' | tr -d "a-z+" | awk '{printf "%d",$1}'`
report=`  echo 0$wtd | sed 's/+report+/1/'  | tr -d "a-z+" | awk '{printf "%d",$1}'`
eval=`    echo 0$wtd | sed 's/+eval+/1/'    | tr -d "a-z+" | awk '{printf "%d",$1}'`
cleanup=` echo 0$wtd | sed 's/+cleanup+/1/' | tr -d "a-z+" | awk '{printf "%d",$1}'`

echo;echo "whattodo: $wtd";echo
echo "whattodo: clean     --> $clean"
echo "whattodo: bldngr    --> $bldngr"
echo "whattodo: phtrans   --> $phtrans"
echo "whattodo: bldlm     --> $bldlm"
echo "whattodo: prunelm   --> $prunelm"
echo "whattodo: report    --> $report"
echo "whattodo: eval      --> $eval"
echo "whattodo: cleanup   --> $cleanup"

echo;echo "parameters:";echo
checkpar dirsource $dirsource
checkpar outdir $outdir
checkpar cleantext $cleantext

checkpar version $version
checkpar language $language
checkpar cleanoptions $cleanoptions
checkpar actualcoding $actualcoding
checkpar finalcoding $finalcoding

checkpar list "$list"
checkpar lsep "$lsep"
checkpar enne $enne
checkpar lmtype $lmtype
checkpar tutto $tutto

checkpar transcriber $transcriber
checkpar reducelex "$reducelex"

checkpar prunes $prunes
checkpar onlyupper2lower $onlyupper2lower

mkdir -p $outdir

if [ $clean = 1 ]
then header "cleaning"
     echo "listafuori $list"
     sh $cleantext $dirsource $outdir "$list" \
	$version ALL $language $cleanoptions \
	$actualcoding $finalcoding $onlyupper2lower 10 > $outdir/CleanText.rep 2>&1
     echo check $outdir/CleanText.rep; echo
else header "no need for cleaning"
fi

if [ $bldngr = 1 ]
then header "building ngrams"
     if [ -f $outdir/$tutto.${enne}ngt ]
     then echo file $outdir/$tutto.${enne}ngt existing, skipping..
     else echo building file $outdir/$tutto.${enne}ngt ...
	  cnt=0
	  all=""
	  for xx in `echo $list | sed "s/@@@/ /g"`
	  do f=`echo $xx | cut -d":" -f2`
	     bname=$outdir/${f}_$version.nopunct
	     $DICT -i="zcat $bname.gz" -o=$bname.dict -f=yes > $bname.dict.rep 2>&1
	     if [ $cnt -eq 0 ]
	     then cnt=1
		  cp $bname.dict $outdir/$tutto._$cnt.dict
	     else
		 cnt2=`expr $cnt + 1`
		 $CDICT $outdir/$tutto._$cnt.dict $bname.dict 10000000 1 > $outdir/$tutto._$cnt2.dict
		 cnt=$cnt2
	     fi
	     zcat $bname.gz | $NGCOUNT -n=$enne -oMode=ngt > $bname.${enne}ngt
	     all="$all $bname.${enne}ngt"
	     # all2="$all2 $bname.gz"
	  done
	  cp $outdir/$tutto._$cnt.dict $outdir/$tutto.dict
	  $NGCOUNT -Merge=1 $all > $outdir/$tutto.${enne}ngt 
	  # zcat $all2 | $NGCOUNT -n=$enne -oMode=ngt > $outdir/$tutto.${enne}ngt2 
     fi
else header "no need for building ngrams"
fi

if [ $phtrans = 1 ]
then header "building phonetic, maybe reduced, lexicon"
     for size in `echo $reducelex`
     do echo $size
	if [ -f $outdir/$tutto.${size}K.smp ]
	then echo file $outdir/$tutto.${size}K.smp existing, skipping ...
	else echo building file $outdir/$tutto.${size}K.smp ...
	     if [ $size = "all" ]
	     then echo keep all lexicon
		  cp $outdir/$tutto.dict $outdir/$tutto.${size}K.dict
	     else echo reduce lexicon to first ${size}K items
		  $RDICT $outdir/$tutto.dict ${size}000 $outdir/$tutto.${size}K.dict.rep > $outdir/$tutto.${size}K.dict
	     fi 
	     cat $outdir/$tutto.${size}K.dict | awk '{print $1}' | grep -v DICTIONARY > $outdir/$tutto.${size}K.dic
	     $transcriber $outdir/$tutto.${size}K.dic $outdir/$tutto.${size}K.smp > $outdir/$tutto.${size}K.smp.rep  2>&1
	     echo "<unk> @bg"  >> $outdir/$tutto.${size}K.smp
	     echo "@NULL @bg"  >> $outdir/$tutto.${size}K.smp
	     # echo "<s> @bg"  >> $outdir/$tutto.${size}K.smp # already in place
	     # echo "</s> @bg" >> $outdir/$tutto.${size}K.smp # already in place
	     cat $outdir/$tutto.${size}K.smp | awk '{for(i=2;i<=NF;i++){print $i}}' | sort | uniq -c > $outdir/$tutto.${size}K.phn
	     if [ -n "$completedic" ] # if [ 1 = 1 ]
	     then echo merging lexica
		  cmpl=$completedic.${size}K
		  cat $otherdic.lex $outdir/$tutto.${size}K.dic | sort -u > $cmpl.dic
		  $transcriber $cmpl.dic $cmpl.smp > $cmpl.smp.rep  2>&1
		  echo "<unk> @bg"  >> $cmpl.smp 
		  echo "@NULL @bg"  >> $cmpl.smp 
		  # echo "<s> @bg"  >> $cmpl.smp  # already in place
		  # echo "</s> @bg" >> $cmpl.smp  # already in place
		  cat $cmpl.smp | awk '{for(i=2;i<=NF;i++){print $i}}' | sort | uniq -c > $cmpl.phn
	     fi
	fi
	echo "lexicon $outdir/$tutto.${size}K.smp done, should be ok"
     done
else header "no need for building phonetic lexica"
fi

if [ $bldlm = 1 ]
then header "build lms"
     for size in `echo $reducelex`
     do echo; echo build arpa LM using dict $tutto.${size}K.dict
	outout=$outdir/$tutto.$enne.${size}K.$lmtype
	if [ -f $outout.arpa.gz ]
	then echo file $outout.arpa.gz existing, skipping..
	else echo building file $outout.arpa.gz ...
	     $TLM -lm=$lmtype -n=$enne -dub=10000000 -tr=$outdir/$tutto.${enne}ngt \
		  -d=$outdir/$tutto.${size}K.dict -ps=y -oarpa=$outout.arpa > $outout.arpa.rep  2>&1
	     # $COMPILELM $outout.arpa $outout.blmfull > $outout.blmfull.rep  2>&1
	     # rm -f $outout.arpa # ok questo non lo uso piu' - falso
	     gzip $outout.arpa
	fi
     done
else header "no need for building lms"
fi

if [ $prunelm = 1 ]
then header "pruning lms $prunes"
     for size in `echo $reducelex`
     do echo; echo build pruned arpa LM using dict $tutto.${size}K.dict
	blmfull=$outdir/$tutto.$enne.${size}K.$lmtype
	for xx in `echo $prunes | sed "s/@@@/ /g"`
	do p=`echo $xx | cut -d":" -f1`        # $plabel # "p1"
	   thresh=`echo $xx | cut -d":" -f2`   # $pthresh "--threshold=1e-9,1e-9,1e-9,1e-9,1e-9"
	   echo p $p thresh $thresh
	   outout=$outdir/$tutto.$enne.${size}K.$lmtype.$p
	   if [ -f $outout.arpa.gz ]
	   then echo file $outout.arpa.gz existing, skipping..
	   else echo building file $outout.arpa.gz ...
		if [ "$thresh" = "none" ]
		then echo no pruning needed, just link using label $p
		     # $tutto.$enne.$lmtype.blmfull     original blm
		     # $tutto.$enne.$lmtype.arpa        original arpa
		     # bn=`basename $blmfull.blmfull`
		     bn=`basename $blmfull.arpa.gz`
		     ln -s $bn $outout.arpa.gz
		     # bn=`basename $blmfull.arpa`
		     # ln -s $bn $outout.arpa
		else echo pruning arpa LM with label $p, thr $thresh
		     $PRUNELM $thresh $blmfull.arpa.gz $outout.arpa
		     # .blm useful only for building .fsn 
		     # $COMPILELM $outout.arpa $outout.blm
		     gzip $outout.arpa
		fi > $outout.arpa.rep
	   fi
	done
     done
else header "no need for pruning lms"
fi

if [ $report = 1 ]
then header "building corpora report"
     if [ -f $outdir/ReportTXT.rep ]
     then echo file $outdir/ReportTXT.rep existing, skipping..
     else echo building report $outdir/ReportTXT.rep
	  if [ 1 = 1 ]
	  then echo file $outdir/ReportTXT.rep;echo;echo "size of original and processed corpora";echo
	       for xx in `echo $list | sed "s/@@@/ /g"`
	       do  uno=`echo $xx | cut -d":" -f1`
		   due=`echo $xx | cut -d":" -f2`
		   wc1=`zcat $dirsource/$uno | perlwc`
		   wc2=`zcat $outdir/${due}_$version.basetxt.gz | perlwc`
		   wc3=`zcat $outdir/${due}_$version.nopunct.gz | perlwc`
		   wc4=`cat  $outdir/${due}_$version.baselex | wc -l`
		   if [ 1 = 1 ]
		   then echo $wc1 $dirsource/$uno
			echo $wc2 $outdir/${due}_$version.basetxt.gz
			echo $wc3 $outdir/${due}_$version.nopunct.gz
		   fi | awk '{printf "%9d lines, %12d words - %s\n",$1,$2,$3}'
  	    	   echo $wc4 $outdir/${due}_$version.baselex | \
		       awk '{printf "%9d lexical items - %s\n",$1,$2}'
		   echo $wc1 $wc3 $due | awk '{printf "rapporto compressione parole sorgente/nopunct: %10d/%10d = %6.2f per %s\n", $2,$4,100*$2/$4,$5}'
		   echo
	       done
	       echo
	  fi > $outdir/ReportTXT.rep
     fi
     if [ -f $outdir/ReportLM2.rep ] # cosi' lo riscrive sempre, tanto questo e' veloce
     then echo file $outdir/ReportLM.rep existing, skipping..
     else echo building report $outdir/ReportLM.rep
	  if [ 1 = 1 ]
	  then echo file $outdir/ReportLM.rep;echo; echo lexicon size and number of ngrams of corpora in $outdir;echo 
	       for ngt in `ls $outdir/*ngt`
	       do  nn=`echo $ngt | awk -F. '{print $NF}' | sed "s/ngt//"`
		   bn=`basename $ngt`
		   dict=`echo $ngt | sed "s/.${nn}ngt/.dict/"`
		   dd=`head -1 $dict | awk '{print $3}'`
		   ngr=`head -1 $ngt | awk '{print $3}'`
		   echo $dd $ngr $nn $bn | \
		       awk '{printf "%9d dict size, %12d %d-grams - %s\n",$1,$2,$3,$4}'
	       done

	       echo;echo "size of phonetic lexica in $outdir";echo
	       for smp in `ls $outdir/*smp ${completedic}*smp`
	       do ff=`basename $smp`
		  dic=`echo $smp | sed "s/\.smp/.dic/"`
		  phn=`echo $smp | sed "s/\.smp/.phn/"`
		  dics=`cat $dic|wc -l`
		  smps=`cat $smp|wc -l`
		  phns=`cat $phn|wc -l`
		  echo $dics $smps $phns $ff 
	       done | awk '{printf "%10d items, %10d phonetic transcr, %5d phones - %s\n",$1,$2,$3,$4}'
	       for rep in `ls $outdir/$tutto.*K.dict.rep`
	       do echo $rep 
		  cat $rep
	       done

	       echo;echo "size of LMs in $outdir";echo
	       # for file in `ls $outdir/*blmfull $outdir/*blm $outdir/*arpa.gz`
	       for file in `ls $outdir/*arpa.gz`
	       do suf=`basename $file | sed "s/.gz//" | awk -F. '{print $NF}'`
		  ff=`basename $file`
		  dd=`du -sh $file | awk '{print $1}'`
		  if [ $suf = "arpa" ]
		  then zcat $file | head -9 | grep ^ngram | awk -v d=$dd -v f=$ff \
		       'BEGIN{k=0;}{k++;printf "%2s %11s ", $2,$3}END{for(i=k+1;i<=5;i++){printf "%1d= %11s ",i,"--"}printf "%7s %s\n",d,f}'
		  else head -1 $file | awk -v d=$dd -v f=$ff \
		       '{for(i=1;i<=5;i++){if((i+2)>NF){printf "%1d= %11s ",i,"--"}else{printf "%1d= %11d ",i,$(i+2)}}}END{printf "%7s %s\n",d,f}'
		  fi
	       done
	  fi > $outdir/ReportLM.rep
     fi
else header "no need for building corpora report"
fi

if [ $eval = 1 ]
then header "evaluation - still to fix -"
     cleaned=1;
     for xx in `echo $evlist | sed "s/@@@/ /g"`
     do  uno=`echo $xx | cut -d":" -f1`
	 due=`echo $xx | cut -d":" -f2`
	 echo EVAL $uno $due
	 if [ -f $outdir/${due}_$version.nopunct.gz ]
	 then l1=`cat $evsrc/$uno | wc -l`
	      l2=`zcat $outdir/${due}_$version.nopunct.gz | wc -l`
	      if [ $l1 -eq $l2 ]
	      then echo "file $outdir/${due}_$version.nopunct.gz already in place"
	      else cleaned=0
	      fi
	 else cleaned=0
	 fi
     done
     echo cleaned $cleaned
     if [ $cleaned -eq 0 ]
     then echo have to clean eval data
	  echo "listafuori $evlist"
	  sh $cleantext $evsrc $outdir "$evlist" \
	     $version ALL $language buildbase+buildclean+force \
	     $actualcoding $finalcoding $onlyupper2lower 1000 > $outdir/CleanTextEval.rep 2>&1
	  echo check $outdir/CleanTextEval.rep; echo
     else echo eval data already cleaned
     fi
     
     if [ 1 = 1 ]
     then (echo ; echo lexica ; echo) > $outdir/ReportEvalLMfull.rep
	  for xx in `echo $evlist | sed "s/@@@/ /g"`
	  do  uno=`echo $xx | cut -d":" -f1`
	      due=`echo $xx | cut -d":" -f2`
	      for smp in `ls $outdir/*smp`
	      do ff=`basename $smp | sed "s/\.smp//"`
		 dic=`echo $smp | sed "s/\.smp/.dic/"`
		 # echo EVAL $due $outdir/${due}_$version.nopunct.gz  DIC $ff $dic 
		 # echo "zcat $outdir/${due}_$version.nopunct.gz | perloov $dic"
		 zcat $outdir/${due}_$version.nopunct.gz | perloov $dic
		 echo EVAL $due DIC $ff; echo
	      done
	      echo
	  done >> $outdir/ReportEvalLMfull.rep
	  (echo ; echo language models ; echo) >> $outdir/ReportEvalLMfull.rep
	  for xx in `echo $evlist | sed "s/@@@/ /g"`
	  do  uno=`echo $xx | cut -d":" -f1`
	      due=`echo $xx | cut -d":" -f2`
	      # for blm in `ls $outdir/*blm $outdir/*arpa.gz`
	      for blm in `ls $outdir/*arpa.gz`
	      do ff=`basename $blm | sed "s/\.blm//"`
		 # echo EVAL $due BLM $ff
		 zcat $outdir/${due}_$version.nopunct.gz > tmp.$$
		 wwcc=`cat tmp.$$ | wc -l`
		 out=`$COMPILELM -e tmp.$$ $blm | grep "%%"`
		 echo $out - EVAL $due - $wwcc sentences - BLM $ff
		 rm -f tmp.$$
	      done
	      echo
	  done >> $outdir/ReportEvalLMfull.rep
	  grep -v unknown $outdir/ReportEvalLMfull.rep > $outdir/ReportEvalLM.rep

	  cat $outdir/ReportEvalLM.rep
     fi
else header "no need for evaluation"
fi


if [ $cleanup = 1 ]
then header "cleaning up non-necessary data"
     if [ 1 = 1 ]
     then echo ; echo "cleaning up non-necessary data" ; echo "before cleanup:"
	  du -sh $outdir
	  echo; echo "gzipping arpa:"
	  gzip $outdir/*.arpa
	  du -sh $outdir
	  echo; echo "removing:"
          du -sh $outdir/*.${enne}ngt
	  #du -sh $outdir/*.blmfull
	  #du -sh $outdir/*.blm
	  du -sh $outdir/*.normtxt.gz
	  du -sh $outdir/*.basetxt.gz
	  
	  rm -f $outdir/*.${enne}ngt
	  #rm -f $outdir/*.blmfull
	  #rm -f $outdir/*.blm
	  rm -f $outdir/*.normtxt.gz
	  rm -f $outdir/*.basetxt.gz
	  echo; echo "remaining huge files:"
	  ls -laS $outdir | head -30
	  echo; echo "after cleanup:"
	  du -sh $outdir
     fi > $outdir/ReportCleanUp.rep
     echo please check $outdir/ReportCleanUp.rep
else header "no need for cleaning up non-necessary data"
fi

exit
