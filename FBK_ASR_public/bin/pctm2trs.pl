#!/usr/bin/perl

$pctm=$ARGV[0];
$audio=$ARGV[1];
$totalduration=$ARGV[2];
$fakepctm=($ARGV[3] eq "-fakepctm") ? 1 : 0;
$exact=($ARGV[3] eq "-exact") ? 1 : 0;

open(P, "<$pctm") || die "cannot read pctm file $pctm";

#generate header
print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print "<!DOCTYPE Trans SYSTEM \"trans-14.dtd\">\n";
print "<Trans scribe=\"auto\" audio_filename=\"$audio\" version=\"0\" version_date=\"\">\n";
print "<Episode>\n";
print "<Section type=\"report\" startTime=\"0\" endTime=\"$totalduration\">\n";
print "<Turn startTime=\"0\" endTime=\"$totalduration\">\n";
printf "<Sync time=\"%.3f\"/>\n",0.0;
$last=0.0;

while($l=<P>){
    $l=~s/\r?\n//; # bastardo dos
    if($fakepctm && $l=~m/^(\S+)\@([0-9\.]+)\@([0-9\.]+)(.*)$/){
	($id,$t1,$dur,$txt)=($1,$2,$3,$4);
	printf "<Sync time=\"%.3f\"/>\n",($t1+$last)/2; # media dei due precedenti
	$txt=~s/<unk>/ /g;
	print  "$txt\n";
	$last=$t1+$dur;
    }
    elsif($l=~m/^(\S+)\s+([0-9]+)\s+([0-9\.]+)\s+([0-9\.]+)(.*)$/){
	($id,$uno,$t1,$dur,$txt)=($1,$2,$3,$4,$5);
	# printf "<Sync time=\"%.3f\"/>\n",$t1;
	if($exact){printf "<Sync time=\"%.3f\"/>\n",$t1;} # inizio
	else{printf "<Sync time=\"%.3f\"/>\n",($t1+$last)/2;} # media dei due precedenti
	$txt=~s/<unk>/ /g;
	print  "$txt\n";
	if($exact){printf "<Sync time=\"%.3f\"/>\n",($t1+$dur);} # fine
	$last=$t1+$dur;
    }
    else{
	die "cannot parse line <$l>";
    }
}
close(P);

printf "<Sync time=\"%.3f\"/>\n",$totalduration;
#generate footer
print "<\/Turn>\n";
print "<\/Section>\n";
print "<\/Episode>\n";
print "<\/Trans>\n";



