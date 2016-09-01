#!/usr/bin/env bash

[ ! -d html_age ] && mkdir html_age
for i in {1..2480}; do
 echo $i
 curl "http://www.ironman.com/triathlon/events/americas/ironman/mont-tremblant/results.aspx?rd=20160821&race=monttremblant&bidid=$i&detail=1" > html_age/$i.html
 sleep .5
done

echo -e "Name\to.rank\td.rank\tg.rank\tbib\tage" > age.tsv
perl -ne 'BEGIN{sub getnum{ $pat=shift; if(m/\Q$pat/){$_=readline(); print "\t$1" if m/<td>(\d+|-+)</;}} };print "\n$1" if m/h1>([^ ].*)</; print "\t$1" if m| Rank:</strong> ?([\dDNFSQ-]+)</div>|;     getnum("strong>BIB"); getnum("strong>Age");    ' html_age/*html |sed '1d;s/---/NA/g;'>>  age.tsv
