library(dplyr)
library(ggplot2)
library(lubridate)
library(tidyr)

plotResults <- function(filename,agerange) {
   d<-read.table(filename,header=T,sep="\t")

   sumscnt <- sprintf('%s\nT: %d; DNF: %d; DNS: %d',
     agerange,
     nrow(d),
     length(which(d$Finish=='DNF')),
     length(which(d$Finish=='DNS'))
   )

   cat(sumscnt,"\n")
     

   d.long <- d %>% select(Div.Rank,Swim,Bike,Run,Finish) %>% 
    filter(Div.Rank!='---') %>%
    mutate(Div.Rank=as.numeric(as.character(Div.Rank))) %>%
    gather('Part','Time',-Div.Rank) %>%
    mutate(Time=hms(Time),
           Dur=as.numeric(as.duration(Time))/(60*60),
           PerField = Div.Rank/max(Div.Rank) )


   p <- 
    ggplot(d.long)+
    aes(x=Dur,fill=Part) +
    geom_density() +
    geom_point(aes(y=PerField,color=Div.Rank)) +
    facet_wrap(~Part,scale='free')+
    theme_bw() + 
    ylab('rank/max OR density') + xlab('Duration (hours)')+
    ggtitle(sumscnt)

   print(p)
   plotfname=paste0('FinishDensity_',agerange, '.png');
   cat(plotfname,"\n")
   ggsave(file=plotfname,p)
}

# ./getResults.pl '30-34'|sed 's/^Name\t//;s/^\t//'>  WFage.tsv 
plotResults('WFage.tsv','30-34')

# ./getResults.pl 18-24 |sed 's/^Name\t//;s/^\t//'>  SEage.tsv 
plotResults('SEage.tsv','18-24')

# ./getResults.pl |sed 's/^Name\t//;s/^\t//'>  all.tsv 
