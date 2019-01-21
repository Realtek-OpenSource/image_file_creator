#! /usr/bin/perl

#------------------
#
# Gen Market ID Binary
#
#------------------

#------------------
# check argument
#------------------
if ($#ARGV < 1) {
	print "$#ARGV\n";
	die "\nUsage:\n\tgen_market_id.pl <market_id> <market_id_output_file>\n";
}

#------------------
# read argv
#------------------
my $market_id = $ARGV[0];
my $fout = $ARGV[1];
my $final_market_id_temp;
my $final_market_id;

if (index($market_id, "0x") == 0 || index($market_id, "0X") == 0) {
	$final_market_id_temp = substr $market_id, 2;
	$final_market_id = hex($final_market_id_temp);
} else {
	$final_market_id = $market_id;
}

if ($final_market_id > 0xFFFFFFFF) {
	die "\nThe maximum avaliable input value of market_id should be less than 0xFFFFFFFF \n\n";
}

open (MARKET_ID_BIN, ">$fout") or die "cannot open output file $!\n";
print MARKET_ID_BIN pack('I', $final_market_id);
close(MARKET_ID_BIN);
