#!/usr/bin/perl

# riduce un dizionario MA SENZA mantenere il formato per il gigantic lm.
# il numero di parole da tenere e` indicativo per eccesso: vengono
# tenute tutte quelle aventi un numero di occorrenze pari o superiore
# alla soglia, cioe` al numero di occorrenze della ennesima parola
# (ordinata per frequenza)

$wholedict=$ARGV[0];
$enne=$ARGV[1];
$report="$ARGV[2]"; # file di report oppure nulla

########################################################################
# stimo la soglia -  ordino il dizionario per frequenza

open(D, "sort -rn -k +2 $wholedict|") || die "cannot open dict file $wholedict";
$n=0;
while($a=<D>){
    if($a=~m/^(\S+)\s+([0-9]+)\s*$/){
	$n++;
	$thr=$2
	    if($n<=$enne);
    }
    else{
	# print STDERR "discard line $a";
    }
}
close(D);
$t=$n;
########################################################################
# filtro il dizionario - mantenendo l'ordine - tenendo solo le parole
# con frequenza sufficiente

$out="";
## open(D, "$wholedict") || die "cannot open dict file $wholedict";
open(D, "sort -rn -k +2 $wholedict|") || die "cannot open dict file $wholedict";

$n=0;
while($a=<D>){
    if($a=~m/^(\S+)\s+([0-9]+)\s*$/){
	if($2>=$thr){
	    $n++;
	    $out.=$a;
	}
    }
    else{
	# print STDERR "discard line $a";
    }
}
close(D);

print STDERR "$0 - read $t words from $wholedict\n";
print STDERR "desired $enne words - keeped $n words having frequency >= $thr\n";

print "DICTIONARY 0 $n\n";
print $out;

if ($report=~/\S/){
    open(R, ">$report") || die "cannot open report file $report";
    print R "$0 - read $t words from $wholedict\n";
    print R "desired $enne words - keeped $n words having frequency >= $thr\n";
    close(R);
}
