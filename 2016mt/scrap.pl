#!/usr/bin/env perl
#
# iterate through each bib number (total taken from web)
# grab aval info (3x time,pace,rank, transition times, athlete location)
# USAGE:
# ./scrap.pl |  sed '/^\W\+$/d' | tee mt2016.tsv     
#
#
use strict; use feature qw/say signatures/;
no warnings qw/experimental::signatures/;

use Mojo::Base;
use Mojo::UserAgent;
use Data::Dumper;


## DATA HEADERS
#
#general nifo
my @infoh=qw/bib div loc country prof/;
# per event
my @sumh=qw/dist split race pace drank grank orank/;
my @sumhh;
sub addpre($pre,@a) { map { "$pre.$_"} @a }
push @sumhh, addpre($_,@sumh) for qw/swim bike run/;
# transition
my @tth = qw/t1 t2/;

my @allh=(@infoh, @sumhh,@tth);

### parse data
sub bibpage($bibid) {
 # http://track.ironman.com/newathlete.php?rid=214748453&race=monttremblant&bib=1264&v=3.0&beta=&1471866300
 #return "http://www.ironman.com/triathlon/events/americas/ironman/mont-tremblant/results.aspx?rd=20160821&race=monttremblant&bidid=$bibid&detail=1";
 #
 #return "http://track.ironman.com/newathlete.php?rid=214748453&race=monttremblant&bib=$bibid&v=3.0&beta=&1471866300";
 open my $FILE, "<", "html/$bibid.html";
 my @file;
 {local $/; @file=<$FILE>;};
 close $FILE;
 return Mojo::DOM->new(@file);
}

sub parsepage($dom) {
  ##### 
  # general ath info
  #####
  my $gdom = $dom->at('#general-info');
  return undef unless $gdom;

  my @gen= @{$gdom->find('td')->map('all_text')};
  my %h;
  @h{@infoh}=@gen[(2,4,6,8,10)];
  #0 'General Info';
  #2 'BIB';
  #3 '1';
  #4 'Division';
  #4 'MPRO';
  #5 'State';
  #6 'Thousand Oaks CA';
  #7 'Country';
  #8 'USA';
  #9 'Profession';
  #10'Professional Triathlete';
  
  
  ##### 
  # summary stats
  #####
  # 3 repeats (swim,bike,run) of 
  # Split Name   Distance    Split Time  Race Time   Pace  Division Rank  Gender Rank    Overall Rank
  my @sum = @{ $dom->find('tfoot tr td strong')->map('all_text')}; 
  my @sumstat=@sum[ (1..7,9..15,17..23) ] ;
  @h{@sumhh} = @sumstat;
  #   0 = 'Total';
  # 1  = '3.8 km';
  # 2  = '58:59';
  # 3  = '58:59';
  # 4  = '1:33/100m';
  # 5  = '8';
  # 6  = '31';
  # 7  = '36';
  #   8  = 'Total';
  # 9  = '180 km';
  # 10 = '4:30:35';
  # 11 = '5:33:07';
  # 12 = '39.91 km/h';
  # 13 = '2';
  # 14 = '2';
  # 15 = '2';
  #    16 = 'Total';
  # 17 = '42.195 km';
  # 18 = '2:54:53';
  # 19 = '8:29:57';
  # 20 = '4:08/km';
  # 21 = '2';
  # 22 = '2';
  # 23 = '2';
  
  
  
  ## transition time
  my $tables = $dom->find('table');
  my $tt = $tables->[5]->children->find('td')->map('text');
  @h{@tth} = ($tt->[0]->[1], $tt->[0]->[3]);
  

  #######
  # chip intervals
  #####

  ## time steps
  my $bike = $tables->[3]->children->find('td')->map('text');
  my @bike;
  for (@$bike){
     push @bike, [@{$_}[0..4]] if $_->[1];
  }

  my $run = $tables->[4]->children->find('td')->[1]->map('text');
  my @run;
  for my $int (1..8) {
   my $s=($int-1)*8;
   my $e=$int*8 - 4;
   my @sub=@{$run}[$s..$e];
   push @run, [@sub] if $sub[1];

  }
  
  my %c=(bike=>[@bike],run=>[@run]);
  
  #say join "\t", @gen[(2,4,6,8,10,12,14)], @ath[(2,4,6,8)],@all[(49,51)];
  return (overview=>{%h},chipped=>{%c} );
}

sub rmkm {
  $_=shift;
  s:km/h::g; s:/km::g; s/km//g;
  s/ //g;
  return($_);
}

# write out array of arrays with bib and type 
# also remove km 
sub writesplits($f,$bib,$type,$a) {
 say $f join("\t",$bib, $type, map {rmkm($_)}  @{$_}) for (@{$a});
}
sub writewide($f,$h) {
 say $f join("\t",@{$h}{@allh});
}

#open my $longf, '>', 'long.tsv';
open my $widef, '>', 'wide.tsv';


my @head=qw"bib type total.dist intv.dist split.time total.time pace";
#say $longf join("\t",@head);
say $widef join("\t",@allh);

for my $bibid (1..2408) {
 my %a=parsepage(bibpage($bibid));
 next unless %a;
 #writesplits($longf,$a{overview}->{bib},$_,$a{chipped}->{$_}) for qw/bike run/;
 writewide($widef,$a{overview});
}

#close $longf;
close $widef;
exit 0;
