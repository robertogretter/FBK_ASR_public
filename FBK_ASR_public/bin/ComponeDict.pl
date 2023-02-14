#!/usr/bin/perl

$dict1=$ARGV[0];
$dict2=$ARGV[1];
$enne=$ARGV[2];
$mul1=$ARGV[3] || 0; # fattore moltiplicativo per il primo dizionario

%d12=();
%d1=();
$d12s=0;
open(D,"<$dict1") || die "cannot open dict $dict1";
$l=<D>;
$l=~m/^\s*(\S+)\s+(\d+)\s+(\d+)\s*$/ || die "error in line $_";
$h1=$3;
$c1=0;
$big1=0;
while($l=<D>){
    $l=~m/^\s*(\S+)\s+(\d+)\s*$/ || die "error in line $_";
    ($w,$c)=($1,$2);
    $d1{$w}=$c;
    $d12{$w}=$c;
    $d12s++;
    $c1++;
    $big1=$big1>$c?$big1:$c;
}
close(D);
print STDERR "header dict1 $h1 $c1 $big1 $dict1\n";

%d2=();
open(D,"<$dict2") || die "cannot open dict $dict2";
$l=<D>;
$l=~m/^\s*(\S+)\s+(\d+)\s+(\d+)\s*$/ || die "error in line $_";
$h2=$3;
$c2=0;
$big2=0;
while($l=<D>){
    $l=~m/^\s*(\S+)\s+(\d+)\s*$/ || die "error in line $_";
    ($w,$c)=($1,$2);
    $d2{$w}=$c;
    if(defined($d12{$w})){
	$d12{$w}+=$c;
    }
    else{
	$d12{$w}=$c;
	$d12s++;
    }
    $c2++;
    $big2=$big2>$c?$big2:$c;
}
close(D);
print STDERR "header dict2 $h2 $c2 $big2 $dict2\n";

print STDERR "header d12s $d12s\n";


if($mul1 <=0){ # echo computing mul factor
    $mul2="$big2 / $big1 ->"; # `echo $max1 $max2|awk '{print $2"/"$1"->"}'`
    $mul1=($big2+1)/($big1+1); # `echo $max1 $max2|awk '{print int($2/$1)+1}'`
    print STDERR " computing mul factor \n max1 $big1 \n  max2 $big2 \n  mul1 $mul2 $mul1\n";
}

$limit=$d12s<$enne?$d12s:$enne;

print STDERR "limit $limit\n";

print "DICTIONARY 0 $limit\n";

@lex12=();
for $k (keys %d12){
#    print "$k $d12{$k} - $d1{$k} - $d2{$k} -\n";
    if($mul1 == 1){
	push @lex12, "$d12{$k} $k $d12{$k}";
    }
    else{
	$s=int($d1{$k}*$mul1+$d2{$k});
	push @lex12, "$s $k $d12{$k}";
    }
}
@lex12=sort {$b <=> $a} @lex12;
for($i=0;$i<$limit;$i++){
    $lex12[$i]=~m/(\S+) (\S+) (\S+)/;
    print "$2 $3\n";

    print STDERR  "$1 $2 $3\n"
	if($i<=3 || $i>=($limit-3));
}

