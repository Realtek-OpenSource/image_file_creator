#! /usr/bin/perl

#------------------
#
# Gen FW header binary
#
#------------------

#------------------
# check argument
#------------------
if ($#ARGV < 4) {
	print "$#ARGV\n";
	die "\nUsage:\n\tgen_fw_header.pl <MAGIC_WORD><FW_TYPE> <FW_SIZE> <FW_REALSIZE> <fw_header_output_file>\n";
}

#------------------
# read argv
#------------------
my $magic_word = $ARGV[0];
my $fw_type = $ARGV[1];
my $fw_size = $ARGV[2];
my $fw_real_size = $ARGV[3];
my $fout = $ARGV[4];

my $header_size_byte = 32;

open (FW_HEADER_BIN, ">$fout") or die "cannot open output file $!\n";

print FW_HEADER_BIN pack('L', hex($magic_word));
print FW_HEADER_BIN pack('L', hex($fw_type));
print FW_HEADER_BIN pack('L', hex($fw_size));
print FW_HEADER_BIN pack('L', hex($fw_real_size));
# last 16 bytes were reserved.
$header_size_byte -= 16;

while ($header_size_byte > 0) {
	print FW_HEADER_BIN pack('L', 0);
	$header_size_byte -= 4;
}

print "output fw_header file - " . $fout . " complete !\n";

close(FW_HEADER_BIN);
