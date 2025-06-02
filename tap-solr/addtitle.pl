use List::MoreUtils qw(firstidx);

chomp;

$i++;

s/\xcd/'/g;
s/\x0b//g;
s/\xca/ /g;
s/\r//g;
# remove spurious decimal digits
s/\.0+\t/\t/g;

@cols = split(/\t/,$_,-1);
#@cols = split /\t/;

if ($i == 1) {
  $dtype_col = firstidx { $_ eq 'DTYPE_s' } @cols;
  $key_col = firstidx { $_ eq 'KEY_s' } @cols;
  $site_col = firstidx { $_ eq 'SITE_s' } @cols;
  $op_col = firstidx { $_ eq 'OP_s' } @cols;
  $sq_col = firstidx { $_ eq 'SQ_s' } @cols;
  $lot_col = firstidx { $_ eq 'LOT_s' } @cols;
  $area_col = firstidx { $_ eq 'AREA_s' } @cols;
  $roll_col  = firstidx { $_ eq 'ROLL_s' } @cols;
  $exp_col  = firstidx { $_ eq 'EXP_s' } @cols;
  $tno_col  = firstidx { $_ eq 'T_s' } @cols;
  $season_col  = firstidx { $_ eq 'YEAR_s' } @cols;
  $notes_col  = firstidx { $_ eq 'NOTES_s' } @cols;
  $material_col  = firstidx { $_ eq 'MATERIAL_s' } @cols;
  $class_col  = firstidx { $_ eq 'CLASS_s' } @cols;
  print $_ . "\tT_i\tTITLE_s\tKEY2_s\n";
  next;
}

my ($roll, $exp, $op, $sq, $area, $lot, $fea, $reg, $site, $year, $tno, $b, $etc, $notes, $material, $class);

$tno = '';
unless ($tno_col == -1) {
  $tno = @cols[$tno_col];
  if ($tno =~ /^[\d\.]+$/){
    $tno = int($tno);
  }
  elsif ($tno eq '') {
    @cols[$tno_col] = 'no T#';
  }
  else {
    @cols[$tno_col] = '';
    #warn "tno :$tno:, $tno_col, $_";
    $tno = '';
  }
}

my $title = '';
my $key = '';
#if ($tno eq '') {
if (1) {
  $dtype = @cols[$dtype_col] unless ($dtype_col == -1) ;
  $key = @cols[$key_col] unless ($key_col == -1) ;
  $site = @cols[$site_col] unless ($site_col == -1) ;
  $op = @cols[$op_col] unless ($op_col == -1) ;
  $sq = @cols[$sq_col] unless ($sq_col == -1) ;
  $lot = @cols[$lot_col] unless ($lot_col == -1) ;
  $area = uc @cols[$area_col] unless ($area_col == -1) ;
  $roll = @cols[$roll_col] unless ($roll_col == -1) ;
  $exp = @cols[$exp_col] unless ($exp_col == -1) ;
  $season = @cols[$season_col] unless ($season_col == -1) ;
  $class = @cols[$class_col] unless ($class_col == -1) ;
  $material = @cols[$material_col] unless ($material_col == -1) ;
  $material = uc $material ;
  # $material = join " ", map { ucfirst lc $_ } split " ", $material;
  if ($notes_col != -1) {
    $notes = @cols[$notes_col];
    #$notes =~ s/(^[\p{L}\W]+)$/\U\1/g;
    $notes = join '', map { ucfirst lc $_ } split /(\s+)/, $notes;
    $notes =~ s/(Clm|Bvm|Cm)/uc($1)/egi;
    $notes =~ s/\.//g;
    $notes =~ s/^\s+|\s+$//g;
    @cols[$notes_col] = $notes;
  }
  $roll = "Roll$roll" if ($roll);
  $exp = "Exp$exp" if ($exp);
  $sq = "Sq$sq" if ($sq);
  $op = "Op$op" if ($op);
  $lot = "Lot$lot" if ($lot);
  $area = "Area$area" if ($area);
  $title = $key;
  if ($dtype =~ /(photologs|images)/) {
    $key = "$site $season $roll $exp ($op $sq $lot $area $level)" ;
    $title = "T$tno: $key" if ($tno ne '');
  }
  elsif ($dtype eq 'merged records') {
    $key = "$key ($op $sq $lot $area $level)" ;
  }
  else {
    $key = "$site $season $op $sq $lot $area $level" ;
  }
  $title .= " $class $notes $material";
  $title =~ s/ +/ /g;
  $title =~ s/ +\)/)/g;
  $title =~ s/\( *\)//g;
  $key =~ s/ +/ /g;
  $key =~ s/ +\)/)/g;
  $key =~ s/\( *\)//g;
}

$_ = join("\t", @cols);
print $_ . "\t$tno\t$title\t$key\n" ;
