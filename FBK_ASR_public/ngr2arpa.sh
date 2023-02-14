#!/bin/sh

# for wavlm (no phonetic transcription, bin lm)
# sh ngr2arpa.sh corpora/italian/all.3ngt corpora/italian/all.128K.dict corpora/italian/all.arpa wavlm-newswiki-it-RG

# for kaldi (phonetic transcription, arpa lm)
# sh ngr2arpa.sh ../SmarTerpAdaLM/corpora/italian/all.3ngt  ../SmarTerpAdaLM/corpora/italian/all.128K.dict  ../SmarTerpAdaLM/corpora/italian/all.arpa none

ngr=$1               # input ngram table
dict=$2              # input dictionary (.dict)
arpa=$3              # arpa LM
newfolder=$4         # output folder for bin LM - none means do not do it

. ./here.sh

enne=3               # ngram order
lm="msb"             # modified shift beta
dub=6000000          # max hyp number of lexicon size

dic=`echo $dict | sed 's/\.dict/.dic/'`
smp=`echo $dict | sed 's/\.dict/.smp/'`


transcriber=$here/NorTex/trascrittore/TrascriviItalianoEO
wavlmtemplate="./wavlm-large-it-cv10_Template"

if [ -f $arpa ]
then echo file $arpa already in place
else echo "$TLM -lm=$lm -n=$enne -dub=$dub -tr=$ngr -d=$dict -ps=y -oarpa=$arpa"
     $TLM -lm=$lm -n=$enne -dub=$dub -tr=$ngr -d=$dict -ps=y -oarpa=$arpa
fi

if [ -f $dic ]
then echo file $dic already in place
else echo "cat $dict | awk '{print $1}' | grep -v DICTIONARY > $dic"
     cat $dict | awk '{print $1}' | grep -v DICTIONARY > $dic
fi

if [ "$newfolder" = "none" ]
then echo build phonetic lexicon
     echo "$transcriber $dic $smp"
     $transcriber $dic $sm
     echo "build pruned arpa LM (too big for kaldi)"
     pthresh="--threshold=1e-8,1e-8,1e-8,1e-8,1e-8"
     plabel="p2"
     parpa=`echo $arpa | sed s/.arpa/.$plabel.arpa/`
     echo "$PRUNELM $pthresh $arpa $parpa"
     $PRUNELM $pthresh $arpa $parpa
     gzip $parpa
else echo build bin LM
     if [ -f $newfolder/language_model/3gram.bin ]
     then echo bin LM $newfolder/language_model/3gram.bin already in place
     else echo "cp -ra $wavlmtemplate $newfolder"
	  echo "./bin/kenlm_build_binary $arpa $newfolder/language_model/3gram.bin"
	  echo "cp $dic $newfolder/language_model/unigrams.txt"
	  cp -ra $wavlmtemplate $newfolder
	  ./bin/kenlm_build_binary $arpa $newfolder/language_model/3gram.bin
	  cp $dic $newfolder/language_model/unigrams.txt
     fi
fi

gzip $arpa

