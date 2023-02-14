#!/bin/sh

pwd=`pwd`
audiofolder=$1
outputfolder=$2


printNwords()
{
    n=$1
    l=$2
    awk -v n=$n -v l=$l '
    	BEGIN{p=0;printf "%s ",l}
	{for(i=1;i<=NF;i++){p++;if(p<=n){printf "%s ",$i}}}
	END{printf "\n"}'
}

. ./here.sh
NN=100000

for audio in `ls $audiofolder/*.wav` 
do id=`basename $audio | sed "s/.wav//"`
   echo $id
   eval=1

   # ASR normalization
   if [ -f $outputfolder/$id.ts.txt ]
   then echo working on ASR output $outputfolder/$id.ts.txt
	cat $outputfolder/$id.ts.txt | \
	    awk -v n=$id '{for(i=1;i<=NF;i+=3){
			   m1=substr($(i+1),2,length($(i+1))-2);
			   m2=substr($(i+2),1,length($(i+2))-1);
			   printf "%s 1 %.3f %.3f %s 1.0\n",n, m1, m2-m1, $i}}' > $outputfolder/$id.ctm
	awk '{printf "%s ",$5}END{printf "\n"}' $outputfolder/$id.ctm > $outputfolder/$id.txt
	silence=1.0 # silence duration to close a phrase
	whs=50      # words to halve sil
	cat $outputfolder/$id.ctm | ./bin/WordCtm2PhraseCtm.pl -s $silence -whs $whs | \
	    ./NorTex/bin/NumbersIt.pl -ws2d > $outputfolder/$id.pctm
	tdur=`ls -la $audio | awk '{printf "%.3f", ($5-44)/2/16000}'`
	./bin/pctm2trs.pl  $outputfolder/$id.pctm $id $tdur | uniq >  $outputfolder/$id.trs
	cat $outputfolder/$id.txt | awk '{for(i=1;i<=NF;i++){printf "%s ",$i}printf "\n"}' | \
	    ./NorTex/bin/LowUppUTF8.pl | sed "s/'/' /g" | \
	    ./NorTex/bin/NumbersIt.pl -magic -w2dmin 2 | printNwords $NN $id > $outputfolder/$id.norm.asr
	cat $outputfolder/$id.norm.asr | printNwords 20 ASR:

   else echo sorry, no ASR output $outputfolder/$id.ts.txt found
	eval=0
   fi
   
   # reference normalization
   if [ -f $audiofolder/$id.txt ]
   then echo working on reference file $audiofolder/$id.txt
	cat $audiofolder/$id.txt | \
	    sed -r "s/<\S+>/ /g;s/'/' /g" | \
	    ./NorTex/bin/LowUppUTF8.pl | \
	    ./NorTex/bin/NumbersIt.pl -w2d -w2dmin 2 | printNwords $NN $id > $outputfolder/$id.norm.ref
	cat $outputfolder/$id.norm.ref | printNwords 20 REF:
   else echo sorry, no reference file $audiofolder/$id.txt found
	eval=0
   fi

   # evaluation
   if [ $eval = 1 ]
   then  ./TLT2021EvalScript.pl -ref  $outputfolder/$id.norm.ref \
				-test $outputfolder/$id.norm.asr \
				-d 2 > $outputfolder/$id.wer 

	 cat $outputfolder/$id.wer | grep "^trace " | \
	     sort | uniq -c | sort -nr | grep -v " OK_" > $outputfolder/$id.errors.stat.txt

	 echo "ASR errors in $outputfolder/$id.errors.stat.txt"
	 echo "$id " | tr -d "\n"
	 grep "^WER= " $outputfolder/$id.wer
	 echo;echo
   else echo "no evaluation will be performed"
   fi
   
done

cat $outputfolder/*.wer | grep "^trace " | \
    sort | uniq -c | sort -nr | grep -v " OK_" > $outputfolder/all.errors.stat.txt

grep "^WER= "  $outputfolder/*.wer | awk -F: '{print $2,$1}' > $outputfolder/all.wer
grep "^WER= "  $outputfolder/all.wer | tr -d "()" | \
    awk -v l=$outputfolder '{s+=$4;i+=$6;d+=$8;r+=$11;u+=$14;pc="%";}
         END{printf "\nWER= %6.2f%s (S= %4d I= %4d D= %4d) / REFERENCE_WORDS= %4d - UTTERANCES= %4d - all %s\n",(100*(s+i+d)/r),pc,s,i,d,r,u,l;}' \
	     >> $outputfolder/all.wer

head $outputfolder/all.wer

