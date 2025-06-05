use List::MoreUtils qw(firstidx);
use Getopt::Std;

getopt('s');
$input_season = $opt_s;

while (<>) {
chomp;
s/\r//g;
s/"//g;
s/\xca/ /g;
s/\xe6/ /g;
s/^/bags\t/;
s/(nml|nkh|npw)/uc($1)/e;
# remove spurious decimal digits
s/\.0+\t/\t/g;

#$season = '';
#if (/^(NPW|NKH|NML|NKW|PL|KTK)_(\d+)/) { $site = $1; $season = $2;}
#if ($season == '') {$season = ($dir =~ /(\d+)/)[0];}

$i++;

if ($i == 1) {
  $_ = uc($_) . "\tYEAR";
  s/_?#//g;
  s/_//g;
  s/\t/_s\t/g;
  s/$/_s/;
  s/^BAGS/DTYPE/;
  s/FEATURE/FEA/;
  s/DESCRIPTIO(N)?/DESCRIPTION/g;
  s/DISPOSITIO(N)?/DISPOSITION/g;
  s/ /_/g;
  @cols = split/\t/;
  $site_col = firstidx { $_ eq 'SITE_s' } @cols;
  $op_col = firstidx { $_ eq 'OP_s' } @cols;
  $lot_col = firstidx { $_ eq 'LOT_s' } @cols;
  $tno_col  = int(firstidx { $_ eq 'T_s' } @cols);
  $area_col  = int(firstidx { $_ eq 'AREA_s' } @cols);
  $notes_col  = int(firstidx { $_ eq 'NOTES_s' } @cols);
  print $_ . "\n";
  next;
}

@cols = split /\t/;

$tno = int(@cols[$tno_col]);
@cols[$area_col] = uc @cols[$area_col] if ($area_col != -1);

#my ($site,$op, $lot, $season, $title, $notes);
#
#if (1) {
#  $site = @cols[$site_col] unless ($site_col == -1) ;
#  $op = @cols[$op_col] unless ($op_col == -1) ;
#  $lot = @cols[$lot_col] unless ($lot_col == -1) ;
#  $notes = @cols[$lot_col] unless ($notes_col == -1) ;
#  $season = $input_season if ($season eq '');
#}
#else {
#  $title = $tno;
#}

print $_ . "\t$input_season\n" ;

}
