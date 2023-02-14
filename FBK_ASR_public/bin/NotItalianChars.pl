#!/usr/bin/perl

# removes every word containing not Italian chars

while($l=<>){
    $l=~s/\r?\n//; # bastardo dos
    # printf "%s\n",$l;
    @wrds=split(/ +/, $l);
    
    foreach $w (@wrds){
	$wo=$w;
	$w=~s/[a-z \047]//g;
	$w=~s/è//g;
	$w=~s/à//g;
	$w=~s/ù//g;
	$w=~s/ì//g;
	$w=~s/ò//g;
	$w=~s/é//g;
	if($w=~m/\S/){
	    printf STDERR "REMOVE (%s) %s\n",$w,$wo;
	}
	unless($w=~m/\S/){
	    printf "%s ",$wo;
	}
    }
    printf "\n";
}
