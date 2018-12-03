#! /usr/bin/perl

#------------------
#
# Gen trust FW table binary
#
#------------------

#------------------
# check argument
#------------------
if ($#ARGV < 2) {
	print "$#ARGV\n";
	die "\nUsage:\n\tgen_fw_header.pl <TRUST_FW_VERSION><TRUST_FW_CONFIG><fw_header_output_file>\n";
}

#------------------
# read argv
#------------------
my $trust_fw_version = $ARGV[0];
my $trust_fw_config = $ARGV[1];
my $fout = $ARGV[2];
my $image_size_byte = 512;

open (FW_TABLE_BIN, ">$fout") or die "cannot open output file, $!\n";
print FW_TABLE_BIN pack('L', hex(aabbccdd));
print FW_TABLE_BIN pack('L', hex($trust_fw_version));

$image_size_byte -= 8;

open (INPUT_FILES, "$trust_fw_config") or die "cannot open input file, $!\n";

my @values = split(' ', $INPUT_FILES);

while ($line=<INPUT_FILES>){
  chomp $line;
  my $string = $line;
  my ($name, $type, $target_address, $size) = split / /, $string;
  print "name: $name, type: $type, target_address: $target_address, size: $size \n";
  print FW_TABLE_BIN pack('L', hex($type));
  print FW_TABLE_BIN pack('L', hex($target_address));
  print FW_TABLE_BIN pack('L', hex($size));
  print FW_TABLE_BIN pack('L', 0);
  $image_size_byte -= 16;
}

while ($image_size_byte > 0) {
  print FW_TABLE_BIN pack('L', 0);
  $image_size_byte -= 4;
}

print "output trust_fw_table - " . $fout . " complete !\n";
close(FW_TABLE_BIN);
