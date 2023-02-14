#!/bin/sh

here="."
NormTex="$here/NorTex";export NormTex
LC_ALL="C";export LC_ALL

# LD_LIBRARY_PATH="$here/festival/installed/libUnix/"
LD_LIBRARY_PATH="$here/NorTex/trascrittore/TrEng/festival/installed/libUnix/";export LD_LIBRARY_PATH

buildlm=$here/bin/BuildLM.sh
cleantext=$here/bin/CleanTextMar2021
NGCOUNT=$here/bin/x86_64/ngcount
DICT=$here/bin/x86_64/dict
TLM=$here/bin/x86_64/tlm
PRUNELM=$here/bin/x86_64/prune-lm
COMPILELM=$here/bin/x86_64/compile-lm
CDICT=$here/bin/ComponeDict.pl
RDICT=$here/bin/ReduceDic.pl
evalOOVPP=$here/bin/EvalOOVPP.sh
CtxFromSeeds=$here/bin/CtxFromSeeds.pl
W2Vdistance=$here/bin/x86_64/distance
tdiff=$here/bin/tdiff
