if (!require(stringdist)) install.packages("stringdist")
if (!require(PASWR)) install.packages("PASWR")
if (!require(DescTools)) install.packages("DescTools")
if (!require(RecordLinkage)) install.packages("RecordLinkage")
library(DescTools)
library (MASS)
library(dplyr)
library(stringdist)
library(PASWR)
library(dplyr)
library(RecordLinkage)


#Load data set
s<-getwd()
datapath<-paste(s,"/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/Louie_Clean_20180719.csv",sep = "")
#If you cannot load the raw dataset, you need to set it by yourself by matching the csv file name.
result <- read.csv(file=datapath,header=T,stringsAsFactors = FALSE)

#Arrangnig the dataset by data, delete unnecessary variables.
result<- result %>% 
  arrange(desc(date)) %>% 
  select(-ID,-X)

#Adding index cuz the rowname is not functioning very well.
result$ID <- seq.int(nrow(result))

result <- result %>% 
  mutate(gcs=paste(lat,long))

#There is no missing values for titles, nor gcs
#But there are some empty title and gcs, so I am deleting empty titles.
result <- result[!(result$title==""),]

#Let's delete the exact duplicates from the same name "or" the same gcs
dif.ttl.or.dif.gcs<- result %>% 
  filter(!duplicated(title)|!duplicated(gcs)) 

dif.ttl.and.dif.gcs<- result %>% 
  filter(!duplicated(title)&!duplicated(gcs))


#same title
same.title <- result %>% 
  filter(duplicated(title))

#same desc
same.gcs <- result %>% 
  filter(duplicated(gcs))

#same title and same gcs
same.ttl.same.gcs <- same.title %>% 
  filter((ID%in%same.gcs$ID)) %>% arrange(title)

View(dif.ttl.or.dif.gcs %>% arrange(title))

dif.ttl.or.dif.gcs$ti = substr(dif.ttl.or.dif.gcs$title, 1, 4)
dif.ttl.or.dif.gcs$lt = substr(dif.ttl.or.dif.gcs$lat, 4, 5)
dif.ttl.or.dif.gcs$lg = substr(dif.ttl.or.dif.gcs$long, 6, 7)
l.pairs <- RLBigDataDedup(dif.ttl.or.dif.gcs,blockfld = c('ti','lt','lg','rooms'),exclude = c('address','city','country','date','description','location','province','source',"url",'ID','ti','lt','lg'),
                         strcmp=c('title'),strcmpfun = "jarowinkler")
summary(l.pairs)
l.pairs=emWeights(l.pairs)
summary(l.pairs)
l.pairs=emClassify(l.pairs, threshold.upper=0, threshold.lower=-26)
l.possibles <- getPairs(l.pairs)
View(l.possibles)
l.links=getPairs(l.pairs, single.rows = T)
Louie_RL_cleaned <- dif.ttl.or.dif.gcs %>% 
  filter(!ID%in%l.links$id.2) %>% select(-c(gcs,ti,lt,lg,ID))
l.links_for_Zhe=l.links=getPairs(l.pairs)
#/Users/hyeongcheolpark/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets
#Save dif.ttl.or.dif.gcs csv and same.ttl.and.same.csv. 
write.csv(Louie_RL_cleaned, file = "/Users/hyeongcheolpark/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/Louie_Clean_20180808.csv")
write.csv(l.links_for_Zhe, file = "/Users/hyeongcheolpark/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/Candidate_Duplicated_Louie_20180808.csv")
#write.csv(same.ttl.same.gcs, file = "Known_Duplicated_Louie_20180808.csv")
                                                                                  