
chomp;
s/\r//g;
my ($dir, $id, $imagename, $stat, $filename) = split /\t/;

$_ = $filename;

# get rid of path, just keep filename
s/.*\///;
$derivative_name = $_;

# rid of extension
s/\..*?$//;

s/ +/ /g;
s/\r//g;

s/ +/ /g;
#s/(Sq|Op|Area|lot|Feat?|Reg) *[A-Z0-9]+\b/uc($1) . "X"/eig;
s/(Ro?l?l?|Op|Sq|Area|T# ?|Lot|Fe?a?t?|Aera)[_ ]*/\1/gi;
s/^tap *(\d{2})/TAP\1/i;
s/Ro?l?l? ?(\d+)/R\1/;

s/^.*\///;

#s/TAP ?90/NKH 90 /i;
#s/TAP ?86/NPW 86 /i;
#s/TAP ?92(.*)NPW/NPW 92 \1/i;
#s/^tap[_\- ]?/TAP /i; # get rid of initial string 'TAP', etc.
s/T#(\d+)/T\1/g; # normalized T numbers

s/TAP (\d+)\-(\d+)/Roll\1-\2/;
s/TAP (\d+) roll (\d+)/Roll\1-\2/;
s/([\d\.]+) *# *(\d+)/R\1-\2/;
#s/(\d+)#(\d+)/\1 #\2/;
s/([RL])(\d+)[_ ]+(\d+)/\1\2_#\3/;
s/([RL])(\d+)[_ ]*NPW([ #])?(\d+)/\1\2_#\4/;
# e.g. NKH_92_Ro_534.thumb.jpg
s/(Ro_?)(\d+)\-(\d+)/R\2 #\3/;
s/(Ro_?)(\d+)/R\2_#\3/;

$tidy_name = $_;
# e.g. Tap 94 Rol 10 #10 op1 lot 38 T#18431 -> Tap_94_Rol_10__10_op1_lot_38_T_18431

@parts = split /[_ ]/;
$season = '';
if (/^(NPW|NKH|NML|NKW|PL|KTK)_(\d{2})/i) { $site = $1; $season = $2;}
if ($season == '') {$season = ($dir =~ /(\d+)/)[0];}

$thumbnailname = "/images/$dir/$imagename";
$thumbnailname =~ s/#/_/g;

$i++;

if ($i == 1) {
  $header = "dtype_s\tt_s\tfilename_s\timagename_s\tthumbnailname_s\tdirectory_s\troll_s\texp_s\top_s\tsq_s\tarea_s\tlot_s\tfea_s\treg_s\tsite_s\tyear_s\tb_s\tetc_s\n";
#  $header = "tidy\troll_s\texp_s\top_s\tsq_s\tarea_s\tlot_s\tfea_s\treg_s\tsite_s\tyear_s\tb_s\tetc_s\n";
  $header = uc($header);
  $header =~ s/(_S+)/lc($1)/eg;
  print $header;
}

my ($roll, $exp, $op, $sq, $area, $lot, $fea, $reg, $site, $year, $tno, $b, $etc);
# print "$_\t" . join('@',@parts) . "\n";
for $p (@parts) {
  # print "xxx${p}xxx\t";
  if ($p =~ /^[RL](o?l?l? ?)(\d+\.?\d?)/i) { $roll = $2;}
  if ($p =~ /^R([\d+\.])\-(\d+)/i) { $roll = $1; $exp = $2;}
  if ($p =~ /^#(\d+)/) { $exp = $1;}
  if ($p =~ /^Op([\d\w]+)/i) { $op = $1;}
  if ($p =~ /^Sq([\d\w]+)/i) { $sq = $1;}
  if ($p =~ /^A[re]+a([\d\w]+)/i) { $area = $1;}
  if ($p =~ /^Lot(\d+)/i) { $lot = $1;}
  if ($p =~ /^Feat?(\d+)/i) { $fea = $1;}
  if ($p =~ /^Reg?([\d\w]+)/i) { $reg = $1;}
  if ($p =~ /^(NPW|NKH|NML|NKW|PL|KTK)/i) { $site = $1;}
  if ($p =~ /^T([\dA-Z]+)/i) { $tno = int($1);}
  if ($p =~ /^Bu?r?(\d+)/i) { $b = $1;}
  # print "$p\t" ;
}
# special case
if (/^(94)/i) {
  unless ($site) {
    $site = "NML";
    $season = "94";
  }
}

$roll = $roll + 0;
$exp = int($exp);
$roll = '' if ($roll == 0);
$exp = '' if ($exp == 0);
$tno = '' if ($tno == 0);
$site =~ tr/a-z/A-Z/;

#print "$tidy_name\t$roll\t$exp\t$op\t$sq\t$area\t$lot\t$fea\t$reg\t$site\t$season\t$b\t$etc";
#print "$derivative_name\t" ;

print "images\t$tno\t$filename\t$derivative_name\t$thumbnailname\t$dir\t" ;
print "$roll\t$exp\t$op\t$sq\t$area\t$lot\t$fea\t$reg\t$site\t$season\t$b\t$etc";
print "\n";

