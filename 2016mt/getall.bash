for i in {1..2480}; do
 echo $i
 curl "http://track.ironman.com/newathlete.php?rid=214748453&race=monttremblant&bib=$i&v=3.0&beta=&1471866300" > html/$i.html
 sleep .5
done
