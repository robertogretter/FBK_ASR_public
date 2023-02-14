#!/bin/sh

# RG, FBK, January 2023 - adaptation from SmarTerp project

# portable tool to perform LM adaptation for WavLM
# given a seedfile, some adaptation text is selected and an adaptation LM is built


# usage:
# sh ./AdaptLM.sh italian audio_samples/PoliticalSpeechesTrs.txt AdaFolderSmall test
# sh ./AdaptLM.sh italian audio_samples/PoliticalSpeechesTrs.txt AdaFolder 

     
lan=$1         # italian, spanish, english
seedfile="$2"  # txt file in UTF8 containing whatever text containing seeds
od=$3          # output will be placed in this folder, that will be created
mode=""
mode="$4"      # optional parameter, "test" or "" or "faketest" -  in case will use "small" data instead of "all" data

wavlmtemplate="./wavlm-large-it-cv10_Template"
wavlmnewfolder="./wavlm-large-it-cv10_$od"

if [ "$mode" = "faketest" ] # not active
then mode="test"
     faketest=1 # data copied rather than calcolated
     echo "sorry, faketest not active"
     exit
else faketest=0
fi

if [ "$mode" = "test" ]
then all="small" # first time will build small.3ngt & small.dict inside zero phase - has to be activated
else all="all"
fi

filter()
{
    if [ "$mode" = "test" ]
    then grep -vE "(dev_v)|(tst_v)|(GlOd)" | grep -E '(wikia[ab])|(EN202)'
    else grep -vE "(dev_v)|(tst_v)|(GlOd)"
    fi
}

if [ ! -f "$seedfile" ]
then echo "seed file $seedfile missing"
     exit
else suf=`basename "$seedfile" | awk -F. '{print $NF}'`
     if [ "$suf" = "txt" ]
     then mkdir -p $od
	  cat "$seedfile" | gzip -c > $od/seedfile.orig.txt.gz
     else echo wrong suffix $suf for $seedfile - txt needed
	  exit
     fi
fi

. ./here.sh

cd $here # must be here to find everything

if [ -z "$lan" ]
then echo language missing
     exit
fi

if [ 1 = 0 ]
then echo copying data, once forever
     # ./bin/DeclAlign_spanish.sh
     if [ $lan = "italian" ]
     then # exit # already done
	  cp /data/disk1/data/kore/gretter/SmarTerpData/LexCovItVanilla3/all.3ngt          $here/corpora/$lan/
	  cp /data/disk1/data/kore/gretter/SmarTerpData/ItalianV3/tutto.dict               $here/corpora/$lan/all.dict
	  cp /data/disk1/data/kore/gretter/SmarTerpData/ItalianV3/tutto.128K.dict          $here/corpora/$lan/all.128K.dict
	  cp /data/disk1/data/kore/gretter/SmarTerpData/ItalianV3/*.nopunct.gz             $here/corpora/$lan/
	  cp /data/disk1/data/kore/gretter/SmarTerpData/SmarTerpASRbenchmark/italian.stm   $here/corpora/$lan/italian.stm
	  cp /data/disk1/data/kore/gretter/word2vec/models/52/model.bin                    $here/corpora/$lan/w2v_52_model.bin
     fi
     # grep -v DICTIONARY ./corpora/italian/all.128K.dict | awk '{print $2,$1}' > ./corpora/italian/all.128K.dic21
     exit
fi

dub=6000000          # max number of lexicon size - it was 1000000
normal=1             # se 1 fa tutto; se 0 prepara per andare a compilare arpa fuori (per l'inglese, troppo grande)

if [ $lan = "italian" ]
then lan2="It"
     AdaDict=$od/SeedFile_v1.nopunct.dict
     cordir=$here/corpora/$lan
     BaseNgr=$here/corpora/$lan/$all.3ngt
     BigDict=$here/corpora/$lan/$all.dict
     MidDict=$here/corpora/$lan/$all.128K.dict
     stm=$here/corpora/$lan/italian.stm
     transcriber=$here/NorTex/trascrittore/TrascriviItalianoEO
     W2Vmodel=$here/corpora/$lan/w2v_52_model.bin
     W2Vseeds="tartaro otturazione carie dente dentista"
     tt=$od/
     fktd=TestDir/TestItRef
else lan2=""
     echo please define language
     exit
fi

# parameters set by $sssss 
maxSons=20           # used in _mS20 - max number of Morpho derivations from a stem
tDiscard=2           # used in _tD3   - threshold: count -le tDiscard to discard candidates 
MinMorLen=4          # min length of a stem to be considered (too short is dangerous) 
CtxW=0               # context words for AdaText - if 0 it is not applied.
ttttt="$all"
sssss="orig_ctw0"
sssss="w2v_ctw60_mS40" # RGMOD
# sssss="orig_ctw60" # RGMOD
#KDS=140
#KDS=80 # RGMOD
KDS=50 # RGMOD
KnownDicSize=`echo $KDS 1000 | awk '{print $1*$2}'`   # max number of lexica entries considered for Seed Words
ddd=$od
lcid="GLOD128K"
enne=3
lm="msb"
pthresh="--threshold=1e-8,1e-8,1e-8,1e-8,1e-8"
plabel="p2"
#pthresh="--threshold=0.5e-8,0.5e-8,0.5e-8,0.5e-8,0.5e-8"
#plabel="p4"
cpref="/data/disk1/data/kore/gretter/SmarTerpData" # just for evaluation

firstime=""
lastime=""
header()
{
    message="$1"
    actime=`date "+%H:%M:%S"`
    echo; echo $message
    if [ -z $lastime ]
    then date
	 echo "start timer" | awk -v t=$actime '{printf "%-15s: %s --> 00:00:00\n",$0,t}'
	 firstime=$actime
    else echo "partial time" | awk '{printf "%-15s: ",$0}'
	 $tdiff $lastime $actime
	 echo "total time" | awk '{printf "%-15s: ",$0}'
	 $tdiff $firstime $actime
    fi
    echo
    lastime=$actime
}

putpoint()
{
    perl -ane 'while(s/([0-9])([0-9]{3})([^0-9])/$1.$2$3/g){};print'
}

expand()
{
    ww=$1
    ll=$2
    ff=$3
    
    echo word $word
    echo "$ww" >> $ff
    if [ $ll = "italian" ]
    then # stem=`echo $ww | perl -ane 'chop();if(length($_)<=6){chop();}else{chop();chop();chop();}print "$_\n";'`
	stem=`echo $ww | perl -ane 's/\r?\n//;while(s/[aeio]$//){}if(length($_)>=4){print "$_\n"};'`
	stem=`echo $MinMorLen $ww | perl -ane 's/\r?\n//;s/(\d+) //;$ll=$1;while(s/[aeio]$//){}if(length($_)>=$ll){print "$_\n"};'`
	echo stem $stem
    fi
    if [ -n "$stem" ]
    then for pair in `grep "^$stem" $BigDict | head -$maxSons | awk '{printf "%s=%s\n",$1,$2}'`
	 do candidate=`echo $pair|cut -d"=" -f1`
	    count=`echo $pair|cut -d"=" -f2`
	    # echo $count $candidate
	    if [ $candidate != $ww ]
	    then if [ $count -le $tDiscard ]
		 then echo DISCARD $count $candidate
		 else echo CONSIDER $count $candidate 
		      echo "$candidate" >> $ff
		 fi
	    fi
	 done
    fi
    echo    
}

check()
{
    cmd="$1"
    ex=`echo $cmd | awk '{print $1}'`
    file $ex
    $cmd > tmp.$$ 2>&1
    head tmp.$$ | awk 'BEGIN{f=1;}{if(NF>=1 && f==1){print $0;f=0;}}'
    rm -f tmp.$$
    echo
}

if [ "$mode" = "test" ]
then if [ $faketest = 1 ]
     then echo skip executables test
     else echo check if executables work
	  check "$cleantext a b c d e f g h i l m"
	  check "$NGCOUNT -a=a"
	  check "$DICT -a=a"
	  check "$TLM -a=a"
	  check "$PRUNELM -a=a"
	  check "$COMPILELM -a=a"
	  check "$CDICT -a=a"
     fi
fi

if [ "$mode" = "test" ]
then if [ $faketest = 1 ]
     then cp $fktd/W2Vtest.txt $od/
     else echo "$W2Vseeds" | awk '{for(i=1;i<=NF;i++){print $i;}}END{print "EXIT"}' | $W2Vdistance $W2Vmodel > $od/W2Vtest.txt
     fi
fi

if [ 1 = 1 ]
then echo studying lexicon coverage and similar things

     # if [ -f $MidDict ]
     if [ 1 = 1 ]
     then echo starting - building $ddd
	  
	  if [ 1 = 0 ]
	  then echo "zero phase, huge ngram preparation, once forever - already in place"
	       if [ 1 = 1 ]
	       then header "zero phase vanilla preparation, huge ngram for language models"

		    if [ -f "$BaseNgr" -a ! -s $ddd/$all.${enne}ngt ] 
		    then echo copio $BaseNgr in $ddd/$all.${enne}ngt
			 cp $BaseNgr $ddd/$all.${enne}ngt
			 # could be better a link but there is some problem with relative paths
			 ls -la $BaseNgr $ddd/$all.${enne}ngt
		    fi
		    
		    if [ -s $ddd/$all.${enne}ngt ]
		    then echo huge ngram file $ddd/$all.${enne}ngt already in place
		    else echo building huge ngram file $ddd/$all.${enne}ngt with unk added
			 allnop=""
			 cnt=0
			 alldic=""
			 for nop in `ls $cordir/*.nopunct.gz | filter`
			 do nopbn=`basename $nop|sed "s/.gz//"`
			    echo "$nop --> $ddd/$nopbn.${enne}ngt"
			    zcat $nop | $NGCOUNT -n=$enne -oMode=ngt > $ddd/$nopbn.${enne}ngt
			    head -2 $ddd/$nopbn.${enne}ngt
			    # note: it cannot be -oMode=ngtb - merge does not work
			    allnop="$allnop $ddd/$nopbn.${enne}ngt"
			    # if [ "$mode" = "test" ]
			    if [ 1 = 1 ]
			    then $DICT -i="zcat $nop" -o=$ddd/$nopbn.dict -f=yes > $ddd/$nopbn.dict.rep 2>&1
				 alldic="$alldic $ddd/$nopbn.dict $ddd/$nopbn.dict.rep"
				 if [ $cnt -eq 0 ]
				 then cnt=1
				      cp $ddd/$nopbn.dict $ddd/$all._$cnt.dict
				 else cnt2=`expr $cnt + 1`
				      $CDICT $ddd/$all._$cnt.dict $ddd/$nopbn.dict 10000000 1 > $ddd/$all._$cnt2.dict
				      cnt=$cnt2
				 fi
				 alldic="$alldic $ddd/$all._$cnt.dict"
			    fi
			 done
			 
			 echo " $NGCOUNT -Merge=1 $allnop > $ddd/$all.${enne}ngt "
			 $NGCOUNT -Merge=1 $allnop > $ddd/$all.${enne}ngt
			 # if [ "$mode" = "test" ]
			 if [ 1 = 1 ]
			 then cp $ddd/$all._$cnt.dict $ddd/$all.dict
			      $RDICT $ddd/$all.dict 128000 $ddd/$all.128K.dict.rep > $ddd/$all.128K.dict
			      echo removing tmp dict files $alldic $ddd/$all.128K.dict.rep
			      rm -f $alldic $allnop $ddd/$all.128K.dict.rep
			      mv $ddd/$all.dict $ddd/$all.128K.dict $ddd/$all.${enne}ngt $here/corpora/$lan/
			      du -sh $here/corpora/$lan/$all.${enne}ngt
			      head -2 $here/corpora/$lan/$all.${enne}ngt
			      echo "if I arrive here, it was just to build small.3ngt, small.dict, small.128K.dict"
			      # exit
			 fi
			 if [ 1 = 0 ]
			 then if [ -s $ddd/$all.${enne}ngt ]
			      then echo huge ngram file built:
				   du -sh $ddd/$all.${enne}ngt
				   head -2 $ddd/$all.${enne}ngt
				   echo removing tmp ngrm files $allnop
				   rm -f $allnop
			      else echo could not build huge ngram file, I stop
				   echo "$NGCOUNT -Merge=1 $allnop > $ddd/$all.${enne}ngt"
				   exit
			      fi
			 fi
		    fi
		    header "GENERATED HUGE ${enne}-grams"
	       fi > $ddd/$lcid.report0.txt
	       echo check $ddd/$lcid.report0.txt
	  fi

	  if [ 1 = 1 ]
	  then echo first phase vanilla preparation
	       if [ 1 = 1 ]
	       then header "first phase vanilla preparation, dictionaries"

		    if [ 1 = 1 ]
		    then echo normalize seed data
			 if [ $faketest = 1 ]
			 then cp $fktd/SeedFile_v1.nopunct.dict $fktd/SeedFile_v1.nopunct.gz $od/
			 else LowUpp=./NorTex/bin/LowUppUTF8.pl
			      NIC=./bin/NotItalianChars.pl
			      zcat $od/seedfile.orig.txt.gz | sed "s+<\/s>++g;s+<s>++g;" | $LowUpp -u2l | tr "_&" " " | tr -d "-" | $NIC | \
				  sed -r "s/ +/ /g" | awk '{printf "<s> %s </s>\n",$0 }' | sed -r "s/ +/ /g" | gzip -c > $od/SeedFile_v1.nopunct.gz 
			      $DICT -i="zcat $od/SeedFile_v1.nopunct.gz" -o=$AdaDict -f=yes > $AdaDict.rep 2>&1
			      # sh $buildlm $here/bin/DeclAlign_$lan.sh \
				# @dirsource=$ddd @outdir=$ddd \
				# -todo "+clean+bldngr+phtrans+bldlm+" > $ddd/SeedNorm.rep 2>&1
			 fi
			 header "NORMALIZE SEED DATA"
		    fi

		    grep -v DICTIONARY $AdaDict | awk '{print $1}' > $ddd/tmpAdaDic
		    grep -v DICTIONARY $MidDict | awk '{print $1}' | head -$KnownDicSize > $ddd/tmpMidDic$KnownDicSize
		    wc $ddd/tmpAdaDic $ddd/tmpMidDic$KnownDicSize $AdaDict $MidDict | grep -vw total
		    bt=`echo $AdaDict | sed "s/.dict/.gz/"`

		    bmark=$ddd/benchmark
		    grep -v "^;;" $stm | grep -v excluded_region | cut -d">" -f2- | \
			tr "().,:;?!" " " | sed "s/\#\*/ /g" | sed "s/\#/ /g" | \
			tee $bmark.ref | tr -s "[:space:]" "[\012*]" | sort | uniq -c > $bmark.lex
		    lexsize=`awk '{if(NF==2){i++}}END{printf "ref_lex= %4d;",i}' $bmark.lex`
		    
		    header "FIND UNKNOWN WORDS - FIRST VANILLA SEEDS"
		    $evalOOVPP $ddd/tmpAdaDic none $ddd/tmpMidDic$KnownDicSize -norm -nonum -notrunc > $ddd/$lcid.oov.orig.txt
		    echo "check VANILLA SEEDS: $ddd/$lcid.oov.orig.txt"
		    grep "unknown first time" $ddd/$lcid.oov.orig.txt | awk '{print $1}' > $ddd/$lcid.oov.orig.lst
		    echo "size of VANILLA SEEDS:"
		    wc $ddd/$lcid.oov.orig.lst
		    echo
		    
		    for seed in `echo $sssss`
		    do seed1=`echo $seed | cut -d_ -f1`
		       if [ $seed1 = "orig" ]
		       then CtxW=`echo $seed | cut -d_ -f2 | tr -d "a-zA-Z"`
			    # seed=$seed1
			    cp $ddd/$lcid.oov.$seed1.lst  $ddd/$lcid.oov.$seed.lst
			    echo orig $ddd/$lcid.oov.$seed.lst
			    wc $ddd/$lcid.oov.$seed.lst
		       fi
		       if [ $seed1 = "mrph" ]
		       then maxSons=`echo   $seed | cut -d_ -f2 | tr -d "a-zA-Z"`
			    tDiscard=`echo  $seed | cut -d_ -f3 | tr -d "a-zA-Z"`
			    MinMorLen=`echo $seed | cut -d_ -f4 | tr -d "a-zA-Z"`
			    CtxW=`echo      $seed | cut -d_ -f5 | tr -d "a-zA-Z"`
			    header "EXPAND VANILLA SEEDS $seed USING MORPHOINFO mS$maxSons tD$tDiscard mmL$MinMorLen ctw$CtxW"
			    if [ -f $ddd/$lcid.oov.$seed.lst ]
			    then echo seeds file $ddd/$lcid.oov.$seed.lst already in place
			    else echo building seeds file $ddd/$lcid.oov.$seed.lst 
				 rm -f $ddd/$lcid.oov.$seed.lst.tmp
				 for word in `cat $ddd/$lcid.oov.orig.lst`
				 do expand $word $lan $ddd/$lcid.oov.$seed.lst.tmp
				 done > $ddd/$lcid.oov.$seed.lst.exp.rep
				 sort -u $ddd/$lcid.oov.$seed.lst.tmp > $ddd/$lcid.oov.$seed.dic
				 $evalOOVPP $ddd/$lcid.oov.$seed.dic none $ddd/tmpMidDic$KnownDicSize -norm -nonum -notrunc > $ddd/$lcid.oov.$seed.txt
				 grep "unknown first time" $ddd/$lcid.oov.$seed.txt | awk '{print $1}' > $ddd/$lcid.oov.$seed.lst
			    fi
			    echo "size of MORPHO EXPANDED VANILLA SEEDS:"
			    wc $ddd/$lcid.oov.$seed.lst
			    echo
			    wc $ddd/$lcid.oov.orig.lst $ddd/$lcid.oov.$seed.dic $ddd/$lcid.oov.$seed.lst | grep -vw total
		       fi
		       if [ $seed1 = "w2v" ]
		       then CtxW=`echo     $seed | cut -d_ -f2 | tr -d "a-zA-Z"`
			    maxSons=`echo  $seed | cut -d_ -f3 | tr -d "a-zA-Z"`
			    header "EXPAND VANILLA SEEDS $seed USING WORD2VEC ctw$CtxW mS$maxSons"
			    if [ -f $ddd/$lcid.oov.$seed.lst ]
			    then echo seeds file $ddd/$lcid.oov.$seed.lst already in place
			    else echo building seeds file $ddd/$lcid.oov.$seed.lst 
				 rm -f $ddd/$lcid.oov.$seed.lst.tmp
				 if [ -z "$W2Vmodel" ]
				 then echo "w2vmodel not defined <$W2Vmodel>"
				 else if [ -f $ddd/$lcid.oov.w2v.lst.exp.rep ]
				      then echo w2v file $ddd/$lcid.oov.w2v.lst.exp.rep already in place
				      else cat $ddd/$lcid.oov.orig.lst | awk '{print $1}END{print "EXIT"}' | \
					      $W2Vdistance $W2Vmodel > $ddd/$lcid.oov.w2v.lst.exp.rep
				      fi
				 fi
				 cat $ddd/$lcid.oov.w2v.lst.exp.rep | tr -d ".,():;\!\?/" | \
				     awk -v n=$maxSons 'BEGIN{m=0;}{if($1 ~ "------"){m=n;}else{if(m>0){print $1;m--;}}}' | \
				     sort -u > $ddd/$lcid.oov.$seed.lst.tmp
				 cat $ddd/$lcid.oov.$seed.lst.tmp $ddd/$lcid.oov.orig.lst | sort -u > $ddd/$lcid.oov.$seed.dic
				 
				 # sort -u $ddd/$lcid.oov.$seed.lst.tmp > $ddd/$lcid.oov.$seed.dic
				 $evalOOVPP $ddd/$lcid.oov.$seed.dic none $ddd/tmpMidDic$KnownDicSize -norm -nonum -notrunc > $ddd/$lcid.oov.$seed.txt
				 grep "unknown first time" $ddd/$lcid.oov.$seed.txt | awk '{print $1}' > $ddd/$lcid.oov.$seed.lst
			    fi
			    echo "size of WORD2VEC EXPANDED VANILLA SEEDS:"
			    wc $ddd/$lcid.oov.$seed.lst
			    echo
			    wc $ddd/$lcid.oov.orig.lst $ddd/$lcid.oov.$seed.dic $ddd/$lcid.oov.$seed.lst | grep -vw total
		       fi
		       for tttt in `echo $ttttt`
		       do ttt=$ddd/$lcid.$seed.$tttt.ada
			  header "FIND ADAPTATION TEXTS FROM UNKNOWN WORDS from $seed - FIRST VANILLA ADA CORPUS from $tttt"
			  if [ -f $ddd/$lcid.$seed.$tttt.txt.gz ]
			  then echo gzipped text file $ddd/$lcid.$seed.$tttt.txt.gz already in place
			  else echo building file $ddd/$lcid.$seed.$tttt.txt
			       if [ $CtxW -ge 1 ]
			       then ctxf="$CtxFromSeeds -dic $ddd/$lcid.oov.$seed.lst -ctxw $CtxW -debug 1"
			       else ctxf="cat"
			       fi

			       echo starting with $bt
			       zcat $bt > $ddd/$lcid.$seed.$tttt.txt
			       if [ $tttt = "wiki" ]
			       then for nop in `ls $cordir/*.nopunct.gz | grep wiki | filter`
				    do echo getting data from $nop
				       zcat $nop | fgrep -f $ddd/$lcid.oov.$seed.lst -w -i | $ctxf >> $ddd/$lcid.$seed.$tttt.txt
				    done
			       else for nop in `ls $cordir/*.nopunct.gz | filter`
				    do echo getting data from $nop
				       zcat $nop | fgrep -f $ddd/$lcid.oov.$seed.lst -w -i | $ctxf >> $ddd/$lcid.$seed.$tttt.txt
				       if [ "$mode" = "test" ]
				       then wwcc=`zcat $nop | wc`
					    echo $wwcc $nop
					    wc $ddd/$lcid.$seed.$tttt.txt
				       fi
				    done
			       fi
			       echo "size of VANILLA ADA CORPORA from $seed and $tttt:"
			       wc $ddd/$lcid.$seed.$tttt.txt
			       gzip $ddd/$lcid.$seed.$tttt.txt
			  fi
			  
			  if [ -f $ddd/$lcid.$seed.$tttt.${enne}ngt ]
			  then echo ngram file $ddd/$lcid.$seed.$tttt.${enne}ngt already in place
			  else echo building file $ddd/$lcid.$seed.$tttt.${enne}ngt
			       zcat $ddd/$lcid.$seed.$tttt.txt.gz | $NGCOUNT -n=$enne -oMode=ngtb > $ddd/$lcid.$seed.$tttt.${enne}ngt
			       $DICT -i="zcat $ddd/$lcid.$seed.$tttt.txt.gz" -o=$ddd/$lcid.$seed.$tttt.dict -f=yes > $ddd/$lcid.$seed.$tttt.dict.rep 2>&1
			       $RDICT $ddd/$lcid.$seed.$tttt.dict 128000 $ddd/$lcid.$seed.$tttt.128K.dict.rep >  $ddd/$lcid.$seed.$tttt.128K.dict
			       echo removing tmp dict files $alldic $ddd/$all.128K.dict.rep

			       # $CDICT $MidDict $ddd/$lcid.$seed.$tttt.dict 10000000 1 > $ttt.dict
			       $CDICT $MidDict $ddd/$lcid.$seed.$tttt.128K.dict 10000000 1 > $ttt.dict
			       cat $ttt.dict | awk '{print $1}' | grep -v DICTIONARY > $ttt.dic
			  fi
			  header "GENERATED $seed - $tttt ADA DICT and ${enne}-grams"
			  
			  $evalOOVPP $bmark.ref none $ttt.dic -norm -nonum -notrunc > $ttt.eval.rep
			  grep "unknown first time"  $ttt.eval.rep | awk '{print $1}' >  $ttt.eval.uft
			  seedsz=`cat $ddd/$lcid.oov.$seed.lst | wc -l`
			  ls=`cat $ttt.dic | wc -l`
			  oov=`grep "^OOV="  $ttt.eval.rep`
			  oovr=`echo $oov | tr "()" " " | awk '{print $9}'`
			  txtsz=`zcat $ddd/$lcid.$seed.$tttt.txt.gz | wc -w | putpoint`
			  echo "SeedSize LexSize OOVrate TXTsize Id"        | awk '{printf "%10s %10s %10s %10s   %s\n",$1,$2,$3,$4,$5}'
			  echo "$seedsz $ls $oovr $txtsz $lan2/$seed-$tttt" | awk '{printf "%10d %10s %10s %10s   %s\n",$1,$2,$3,$4,$5}'
			  echo
		       done
		    done
		    header "END OF FIRST PHASE, generation of a couple of small ADA CORPORA"
		    
	       fi >> $ddd/$lcid.report1.txt
	       echo check $ddd/$lcid.report1.txt
	  fi

	  if [ 1 = 1 ]
	  then echo second phase vanilla preparation
	       if [ 1 = 1 ]
	       then header "second phase vanilla preparation, language models"
		    for seed in `echo $sssss`
		    do echo seed $seed
		       for tttt in `echo $ttttt`
		       do ttt=$ddd/$lcid.$seed.$tttt.ada
			  ls -la $ddd/$lcid.$seed.$tttt.txt.gz $ddd/$lcid.$seed.$tttt.${enne}ngt
			  ls -la $ddd/$lcid.$seed.$tttt.dict $ttt.dict $ttt.dic

			  if [ 1 = 0 ]
			  then echo build sampa lex
			       if [ $faketest = 1 ]
			       then cp $fktd/$lcid.$seed.$tttt.ada.smp $od/
			       else $transcriber $ttt.dic $ttt.smp > $ttt.smp.rep  2>&1
			       fi
			       #echo "<unk> @bg"  >> $ttt.smp
			       #echo "@NULL @bg"  >> $ttt.smp
			       cat $ttt.smp | awk '{for(i=2;i<=NF;i++){print $i}}' | \
				   sort | uniq -c > $ttt.smp.phn
			       header "BUILT $ttt Phonetic Lexicon"
			  fi
			  
			  if [ -f $ttt.arpa.gz ]
			  then echo arpa file $ttt.arpa.gz already in place
			  else echo building file $ttt.arpa.gz

			       if [ $normal = 1 ]
			       then echo normal $normal
				    echo "2"                                                     >  $ttt.slm
				    echo "-slm=$lm -str=$ddd/$lcid.$seed.$tttt.${enne}ngt -sp=0" >> $ttt.slm
				    echo "-slm=$lm -str=$BaseNgr -sp=0"                          >> $ttt.slm
				    #echo "-slm=$lm -str=$ddd/$all.${enne}ngt -sp=0"             >> $ttt.slm
				    if [ $faketest = 1 ]
				    then cp $fktd/$lcid.$seed.$tttt.ada.arpa.gz $od/
					 gunzip $od/$lcid.$seed.$tttt.ada.arpa.gz
				    else $TLM -lm=mix -n=$enne -dub=$dub \
					      -tr=$BaseNgr -d=$ttt.dict -slmi=$ttt.slm -ps=y \
					      -oarpa=$ttt.arpa > $ttt.arpa.rep 2>&1
				    fi
				    # -tr=$ddd/$all.${enne}ngt -d=$ttt.dict -slmi=$ttt.slm -ps=y \
			       else echo too big, try to migrate on some other more powerful machine
				    tttm=./$lcid.$seed.$tttt.ada
				    echo "2"                                                  >  $ttt.migr.slm
				    echo "-slm=$lm -str=./$lcid.$seed.$tttt.${enne}ngt -sp=0" >> $ttt.migr.slm
				    echo "-slm=$lm -str=./$all.${enne}ngt -sp=0"              >> $ttt.migr.slm
				    echo  "./tlm -lm=mix -n=$enne -dub=$dub -tr=./$all.${enne}ngt -d=$tttm.dict \\" >  $ttt.migr.sh
				    echo  " -slmi=$tttm.migr.slm -ps=y -oarpa=$tttm.arpa > $tttm.arpa.rep 2>&1"    >> $ttt.migr.sh
				    #echo "./compile-lm $tttm.arpa $tttm.blmfull > $tttm.blmfull.rep  2>&1 "       >> $ttt.migr.sh
				    echo  "gzip $tttm.arpa "                                                       >> $ttt.migr.sh
				    echo  "./prune-lm $pthresh $tttm.arpa.gz $tttm.$plabel.arpa"                   >> $ttt.migr.sh
				    echo  "gzip $tttm.$plabel.arpa"                                                >> $ttt.migr.sh
				    cp $TLM $COMPILELM $BaseNgr $PRUNELM $ddd/
			       fi
			       # Error: lower order count-of-counts cannot be estimated properly
			       # Hint: use another smoothing method with this corpus.
			       header "GENERATED $seed $tttt ADA ARPA LM"

			       if [ -s $ttt.arpa ]
			       then echo arpa file $ttt.arpa built, go on
				    du -sh $ttt.arpa
				    head $ttt.arpa
				    # $COMPILELM $ttt.arpa $ttt.blmfull > $ttt.blmfull.rep  2>&1
				    if [ -f $ttt.arpa ]
				    then echo preparing wavlm folder with the new lm $ttt
					 newfolder=$wavlmnewfolder.$seed.$tttt
					 if [ ! -f $newfolder/language_model/3gram.bin ]
					 then cp -ra $wavlmtemplate $newfolder
					      ./bin/kenlm_build_binary $ttt.arpa $newfolder/language_model/3gram.bin
					      cp $ttt.dic $newfolder/language_model/unigrams.txt
					 fi
				    fi
				    gzip $ttt.arpa
			       fi
			       if [ -s $ttt.arpa.gz ] # case normal=0
			       then echo arpa file $ttt.arpa already built, go on
			       else echo could not build arpa file $ttt.arpa, I stop
				    exit
			       fi
			       header "GZIPPED $seed $tttt ADA ARPA LM"
			  fi

			  du -sh $ttt.dict $ttt.arpa.gz
			  if [ $faketest = 1 ]
			  then cp $fktd/$lcid.$seed.$tttt.ada.$plabel.arpa.gz $od/
			  else echo pruning LM
			       if [ -f $ttt.$plabel.arpa.gz ]
			       then echo pruned arpa file $ttt.$plabel.arpa.gz already in place
			       else echo building file $ttt.$plabel.arpa.gz
				    echo "$PRUNELM $pthresh $ttt.arpa.gz $ttt.$plabel.arpa"
				    $PRUNELM $pthresh $ttt.arpa.gz $ttt.$plabel.arpa

				    if [ -f $ttt.$plabel.arpa ]
				    then echo preparing wavlm folder with the new lm $ttt.$plabel
					 newfolder=$wavlmnewfolder.$seed.$tttt.$plabel
					 if [ ! -f $newfolder/language_model/3gram.bin ]
					 then cp -ra $wavlmtemplate $newfolder
					      ./bin/kenlm_build_binary $ttt.$plabel.arpa $newfolder/language_model/3gram.bin
					      cp $ttt.dic $newfolder/language_model/unigrams.txt
					 fi
				    fi
				    gzip $ttt.$plabel.arpa
			       fi
			  fi
			  du -sh $ttt.$plabel.arpa.gz
			  header "BUILT $ttt Pruned LMs"

		       done
		       # ## gzip $ddd/all.${enne}ngt - meglio salvarlo in formato binario con -oMode=ngtb
		    done
		    template="./wavlm-large-it-cv10-Template"
		    newfolder="./wavlm-large-it-cv10-Template"

		    # se ci sono gia', non dovrebbe fare nulla
		    if [ -f $ttt.$plabel.arpa.gz ]
		    then echo preparing wavlm folder with the new lm $ttt.$plabel
			 newfolder=$wavlmnewfolder.$seed.$tttt.$plabel
			 if [ ! -f $newfolder/language_model/3gram.bin ]
			 then cp -ra $wavlmtemplate $newfolder
			      zcat $ttt.$plabel.arpa.gz > $newfolder/language_model/3gram.arpa
			      ./bin/kenlm_build_binary $newfolder/language_model/3gram.arpa $newfolder/language_model/3gram.bin
			      cp $ttt.dic $newfolder/language_model/unigrams.txt
			      rm -f $newfolder/language_model/3gram.arpa
			 fi
		    fi

		    if [ -f $ttt.arpa.gz ]
		    then echo preparing wavlm folder with the new lm $ttt
			 newfolder=$wavlmnewfolder.$seed.$tttt
			 if [ ! -f $newfolder/language_model/3gram.bin ]
			 then cp -ra $wavlmtemplate $newfolder
			      zcat $ttt.arpa.gz > $newfolder/language_model/3gram.arpa
			      ./bin/kenlm_build_binary $newfolder/language_model/3gram.arpa $newfolder/language_model/3gram.bin
			      cp $ttt.dic $newfolder/language_model/unigrams.txt
			      rm -f $newfolder/language_model/3gram.arpa
			 fi
		    fi
		    
	       fi >> $ddd/$lcid.report2.txt
	       echo check $ddd/$lcid.report2.txt
	  fi
	  
	  if [ 1 = 0 ]
	  then echo third phase, evaluate
	       if [ 1 = 1 ]
	       then header "third phase, evaluate"
		    bmark=$ddd/benchmark
		    lexsize=`awk '{if(NF==2){i++}}END{printf "ref_lex= %4d;",i}' $bmark.lex`

		    for seed in `echo base $sssss`
		    do echo seed $seed
		       for tttt in `echo $ttttt`
		       do if [ $seed = base ] # $MidDict@$MidLM@$ddd/$lcid.baseLM
			  then dict=$MidDict
			       arpa=$MidLM
			       outp=$ddd/$lcid.baseLM
			       seedsz="0"
			       txtsz="0"
			  else ttt=$ddd/$lcid.$seed.$tttt.ada
			       dict=$ttt.dict
			       arpa=$ttt.$plabel.arpa.gz
			       outp=$ttt.$plabel
			       seedsz=`cat $ddd/$lcid.oov.$seed.lst | wc -l`
			       txtsz=`zcat $ddd/$lcid.$seed.$tttt.txt.gz | wc -w | putpoint`
			  fi
			  lex=`echo $dict | sed "s/\.dict/.dic/"`
			  smp=`echo $dict | sed "s/\.dict/.smp/"`

			  echo $outp
			  ls -la $arpa $dict $lex $smp
			  echo
			  if [ -f $outp.oov.txt ]
			  then echo file $outp.oov.txt already in place
			  else echo building file $outp.oov.txt
			       wc $bmark.ref $bmark.lex | grep -vw total
			       wc $lex $smp | grep -vw total
			       if [ -n "$arpa" -a -f "$arpa" ]
			       then du=`du -sh $arpa | awk '{print $1}'`
				    echo $du $arpa
     				    # ls -la $lex $smp $arpa $trsdir.stm
				    # ./EvalOOVPP.sh $bmark.ref none  $lex -norm -nonum -notrunc > $outp.oov.txt
				    $evalOOVPP $bmark.ref $arpa $lex -norm -nonum -notrunc > $outp.oov.txt
				    
				    grep "unknown first time" $outp.oov.txt | awk '{print $1}' > $outp.oov.txt.uft
				    # cp ../../SmarTerpData/LexCovItVanilla2/GLOD128K.baseLM.oov.txt.uft Italian.GLOD128K.baseLM.oov.txt.uft
				    oov=`grep "^OOV=" $outp.oov.txt `
				    ppp=`grep "^PPP=" $outp.oov.txt `
				    bn=`basename $outp`
				    grep -E "^[A-Z]{3}= " $outp.oov.txt 
				    
				    wc -l $lex | sed -r "s=$cpref/?==" | awk '{printf "%s   %8d words\n",$2,$1}' | putpoint
				    wc -l $smp | sed -r "s=$cpref/?==" | awk '{printf "%s   %8d transcriptions\n",$2,$1}' | putpoint
				    zcat $arpa | head | grep "^ngram " | awk -v d=$du -v n=$arpa 'BEGIN{printf "%s   ",n}{printf "%2s %12d ",$2,$3}END{printf "(%s)\n",d}'| \
					sed -r "s=$cpref/?==" | putpoint
				    echo $ppp
				    echo $oov $lexsize $bn
				    echo;
				    pp=`echo $ppp | tr "=" " " |awk '{print $6,$8}'`
				    ls=`cat $lex | wc -l`
				    oovr=`echo $oov | tr "()" " " | awk '{print $9}'`
				    
				    # (echo "a b c" ;echo "A B C") | awk '{printf "%10s %10s %10s\n",$1,$2,$3}'
				    
				    echo "SeedSize TXTsize LexSize OOVrate PP PPwp LMsize WER Id"        | \
					awk '{printf "%10s %10s %10s %10s %10s %10s %10s %10s   %s\n",$1,$2,$3,$4,$5,$6,$7,$8,$9}'
				    echo "$seedsz  $txtsz  $ls     $oovr   $pp     $du    --  $lan2/$bn" | \
					awk '{printf "%10d %10s %10d %10s %10s %10s %10s %10s   %s\n",$1,$2,$3,$4,$5,$6,$7,$8,$9}'
				    echo
				    header "EVALUATED $bn"
			       else echo cannot find ARPA file $arpa, skipping evaluation
			       fi
			  fi
		       done
		    done
	       fi > $ddd/$lcid.report3.txt
	       echo check $ddd/$lcid.report3.txt
	  fi
	  
     else echo manca qualcosa
     fi

fi

exit

