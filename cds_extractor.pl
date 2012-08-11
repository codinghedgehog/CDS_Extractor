#!/usr/bin/perl
#
# This program extracts the fields of interest from a GB file and outputs to a separate file.
#
# 4/19/2011 - Andrew Pann - Initial development.

use strict;

# Strict requires declaration of variables.
my $infile=$ARGV[0];
my $outfile="$infile.extract";

my ($loc1,$loc2,$gene_id,$locus_tag,$note);
my $cds_found=0;
my $cds_count=0;

# @ARGV is just args array, 0-indexed, and $#ARGV is highest index (not length of array or number of arguments!).
if ($#ARGV < 0){
  print "Usage: $0 <input filename>\n";
  exit 1;
}

print "Will process $infile.\n";
print "Output file is $outfile.\n";

# File I/O setup.
open INFILE, "<$infile" or die "Unable to open input file $infile: $!\n";
open OUTFILE, ">$outfile" or die "Unable to open output file $outfile: $!\n";

while (<INFILE>){

  chomp; # Don't want trailing newlines.

  # Only process lines within a CDS -> gene block (that's the .. operator [inclusive]).
  if (/\s+CDS\s+/ .. /\s+gene\s+/){
    $cds_found=1;

    # Perl has no native switch/case statement, so make our own, rather than dealing with an if-then-elsif jungle.
    SWITCH: for ($_){
      /CDS\s+.*?(\d+)\.\.(\d+).*?/ && do { $loc1=$1; $loc2=$2; last SWITCH;};

      /\/gene="(.+?)"/ && do {$gene_id=$1; last SWITCH;};

      /\/locus_tag="(.+?)"/ && do {$locus_tag=$1; last SWITCH;};

      # Note field is lame, since it can span lines.  Keep building the string until we find the matching start/end quotes.
      /\/note="(.*)/ && do {
        $note="\"$1";
        
        # Assume that a double quote won't show up within (actually, at EOL of) the text line of a note field.
        # Also assuming that each note field will also have a closing " on the last line.
	while ( ! ($note =~ /"$/) ){
          my $line = <INFILE>;
	  chomp $line;
	  $line =~ s/^\s+//g; # Remove leading spaces of line.
          $note .= " " . $line; 
	}
            
        last SWITCH; 
      };
      
      # Default cause - line didn't match anything we cared about, so ignore.
      do { last SWITCH; }
    }
  }
  else{
    if ($cds_found){
      print OUTFILE "$loc1\t$loc2\t$gene_id\t$locus_tag\t$note\n";
      $cds_count++;
      $loc1="";
      $loc2="";
      $gene_id="";
      $locus_tag="";
      $note="";
      $cds_found=0;
      print "\rCoding sequences extracted: $cds_count";
    }
  }
}


print "\nDone.\n";

close INFILE;
close OUTFILE;
