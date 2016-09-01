library(dplyr)
library(tidyr)
library(ggplot2)
library(lubridate)

sec2pace <- function(t){
 
  # N.B. weird stuff if using an origin like year 0
  format(as.POSIXlt(seconds(t*(60^2)),origin="2016-01-01 00:00:00 UTC"), format="%H:%M:%S")
}
readtsv <- function(f,...){ read.table(f,header=T,sep="\t",comment.char="",quote=NULL,...)}


## read in age (and overall place)
d.age <-
   readtsv('age.tsv') %>% 
   mutate(
          drank=as.numeric(as.character(d.rank)),
          status=ifelse(is.na(drank),as.character(d.rank),'F'),
          d.rank=drank
   ) %>% select(-drank)

## read in bulk data -- wide
d<-readtsv('wide.tsv') %>% 
  filter(!is.na(bib)) %>%
   mutate_each(funs( ifelse( grepl("--",as.character(.)) , NA, as.character(.) ) )) %>%
   mutate_each(funs( gsub(' km|/km| km/h|/100m','',as.character(.))),swim.dist,swim.pace,bike.dist,bike.pace,run.dist,run.pace ) %>%
   mutate_each(funs(as.duration(ms(.))),t1,t2) %>%
   mutate_each(funs(as.duration(hms(.))),swim.split,swim.race,
                                         bike.split,bike.race,
                                         run.split,run.race) %>%
   mutate_each(funs(as.numeric(.)),swim.dist,swim.drank,swim.grank,swim.orank,
                                   run.dist,run.drank,run.grank,run.orank,
                                   bike.dist,bike.drank,bike.grank,bike.orank) %>%
   separate(div,c('sex','div'),1)

#d %>% filter(bib==1396)

d<-merge(d.age,d,by='bib')

## occupation
# find top 10
r  <-rle(sort(d$prof))
d.p <- as.data.frame(cbind(r$value,r$lengths))
d.p$V2 <- as.numeric(as.character(d.p$V2))
topocc <- d.p$V1[rev(order(d.p$V2))[1:10]] # ingore "" and "Other"

# find number of people in each div
d.n <- d %>% select(div) %>% group_by(div) %>% summarize(n=n())

d.freq  <-
 d %>%
 filter(prof %in% topocc ) %>% 
 select(prof,div) %>% 
 table %>% 
 as.data.frame %>% 
 merge(d.n,by='div') %>%
 mutate(prctgrp=Freq/n*100)

p<-
 ggplot(d.freq) +
 aes(x=div,y=prof,fill=prctgrp)+
 geom_tile()+
 scale_fill_gradient(low="white",high="red") +
 geom_text(aes(label=Freq,size=prctgrp)) + 
 ggtitle('Profession by division') + theme_bw()
print(p)

# totals
#ggplot(d.n) + aes(x=div,y='total',fill=n,label=n)+geom_tile()+geom_text() + scale_fill_gradient(low="white",high="red") 


# gender histogram by div
d %>% select(div,sex) %>% table %>% as.data.frame %>% ggplot() +aes(x=div,fill=sex,y=Freq)+geom_bar(stat='identity',position='dodge') +theme_bw()+geom_text(aes(label=Freq),position=position_dodge(.9))

# gender histogram by age
g.hist <- 
 ggplot(d) + theme_bw() +
 aes(x=age,group=sex,fill=sex) +
 geom_histogram(alpha=.8,binwidth=1)
 #geom_density(alpha=.8)
print(g.hist) 

## age by total time
d$age2<-d$age**2
summary(lm(data=d,as.numeric(run.race)~age2*sex))

# girls get slower, guys get faster !?
g.agetime <-
 ggplot(d) + theme_bw() +
 aes(x=age,y=as.numeric(run.race)/(60*60),color=sex) +
 geom_point(alpha=.4) +
 geom_smooth(method='lm',formula=y~poly(x,2)) +
 ylab('hours')
print(g.agetime)

d$invage=1/(d$age - mean(d$age,na.rm=T))
summary(lm(data=d,as.numeric(run.race)~age^2+sex))

d %>% select(age,sex) %>% table %>% as.data.frame 


#######

d.long <- d %>% 
          #select(bib, div,age, swim.split,bike.split,run.split) %>% 
          select(bib, div,age, swim.race,bike.race,run.race) %>% 
          gather(event,racetime,-bib,-div,-age) %>%
          mutate(racetime=as.numeric(racetime)/(60^2),
                 event=factor(gsub('.race','',event),levels=c('swim','bike','run'))
                ) 


us=data=d.long[d.long$bib %in% c(1396,1197),]
p <- 
 us %>% 
 ggplot() + theme_bw() +
 aes(x=event,group=bib,color=bib,y=racetime,label=sec2pace(racetime)) +
 geom_point() +geom_line() 
 #geom_point(aes(color=NULL),data=me)+geom_text(aes(label=bib,color=NULL),data=me)
print(p)

#d.div <- d %>% filter(div=="30-34")
