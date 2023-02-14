#!/bin/sh

# declaration, will be included in BuildLM.sh

. ./here.sh

lista="seedfile.orig.txt.gz:SeedFile"

# outdir=/data/disk1/data/kore/gretter/SmarTerpData/EsAlignV2
# mkdir -p $outdir
#dirsource=/data/disk1/data/kore/gretter/SmarTerpData/EsAlignV2
#cleantext=/data/disk1/data/kore/gretter/SmarTerp/CleanTextDec2020

reducelex="all"

list=""
lsep="@@@"
for file in `echo $lista`
do list=$list$file$lsep
done

version="v1"
language="it"
cleanoptions=buildbase+mergelex+buildclean+force       # what to do for cleaning
actualcoding="utf8" # utf8, iso
finalcoding="none"  # i2u, none

enne=3
lmtype=wb  # wb (few data) or msb
tutto=tutto

transcriber=$here/NorTex/trascrittore/TrascriviItalianoEO

pthresh="none"
plabel="p0"
pp0=${plabel}:${pthresh}

prunes=$pp0

testlista=""

evlist=""
for file in `echo $testlista`
do evlist=$evlist$file$lsep
done


