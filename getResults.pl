#!/usr/bin/env perl
use strict; use warnings;
use feature qw/say/;
use File::Slurp qw/slurp/;
use Mojo::DOM;
use Mojo::UserAgent;
use Data::Dumper;
#
#my $data= slurp("./WFrange.html");
#my $dom = Mojo::DOM->new($data);

my $agerange="";
$agerange="&agegroup=".$ARGV[0] if($ARGV[0]);

my $sex="&sex=M";
my $date="20150816";
# 20150816 20140817 20130818 20120819

# results page
sub page {
  return "http://www.ironman.com/triathlon/events/americas/ironman/mont-tremblant/results.aspx?p=$_[0]&race=monttremblant&rd=$date&loc=USA$agerange$sex&so=orank"
}

# bib page
sub biburl {
 my $id=shift;
 return("http://www.ironman.com/triathlon/events/americas/ironman/mont-tremblant/results.aspx?rd=$date&race=monttremblant&bidid=$id&detail=1")

}

# Division    Age     State   Country Profession      Points  Swim    Bike    Run     Overall T1: Swim-to-bike        T2: Bike-to-run
sub athinfo {
 say STDERR "$_[0]";
 my $dom = Mojo::UserAgent->new->get($_[0])->res->dom;
 my $vals = $dom->find('table > tbody > tr > td') -> map('all_text');
 my @vals = map {$vals->[$_]} grep {$_ & 1} 1..$vals->size;

 say STDERR "not 12 elements in: @vals" if $#vals != 12;
 return 1 if join("",@vals) eq "";
 
 say join "\t", @vals;
 sleep .5;
 return 0;
}

sub getAthls {
 my $url = page($_[0]);
 say STDERR $_[0];
 say STDERR $url;
 my $dom = Mojo::UserAgent->new->get($url)->res->dom;
 if($_[0] == 1) {
   my $header= $dom->find('table#eventResults > thead > tr > th > a')->map('text')->join("\t");
   # name field is not picked up by scraper
   # and we dont care about it
   $header =~ s/Name\t"//;
   say $header
 }
 my $athls = $dom->
   find('table#eventResults > tbody > tr')->
   map(sub {$_->find('td')->
                map('text')->
                join("\t")
           })->
   join("\n");

  $athls =~ s/^\t//;

 if($athls=~/[0-9]/) {
   say $athls;
   return 1;
 } else{
   return 0;
 }
}



my $cnt=2684;

# get all of a division
# $cnt++ while(getAthls($cnt));

# get all by bib
say join( "\t", qw/Bib Division    Age     State   Country Profession  Points  Swim  Bike  Run  Overall T1   T2/);
$cnt++ while(athinfo(biburl($cnt)));

exit;
