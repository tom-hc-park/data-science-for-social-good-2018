if (!require(stringdist)) install.packages("stringdist")
if (!require(PASWR)) install.packages("PASWR")
if (!require(DescTools)) install.packages("DescTools")
if (!require(RecordLinkage)) install.packages("RecordLinkage")
library("RecordLinkage")
library(DescTools)
library (MASS)
library(dplyr)
library(stringdist)
library(PASWR)


#Load data set
s<-getwd()
#substr(s, 1, nchar(s)-5) #/Users/hyeongcheolpark/Desktop/DSSG/gitscripper/DSSG-2018_Housing/data_cleaning/_DeDuplication
datapath1<-paste(s,"/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/June_Clean_20180809_val.csv",sep = "")
datapath2<-paste(s,"/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/July_Clean_20180809_val.csv",sep = "")
#If you cannot load the raw dataset, you need to set it by yourself by matching the csv file name.
result1 <- read.csv(file=datapath1,header=T,stringsAsFactors = FALSE,na.strings = c("","NA"))
result2 <- read.csv(file=datapath2,header=T,stringsAsFactors = FALSE,na.strings = c("","NA"))

result=rbind(result1,result2)
#Arrangnig the dataset by title.
result<- result %>% 
  arrange(desc(date)) %>% 
  select(-X.1,-X,-ID)

#Adding index cuz the rowname is not functioning very well.
result$ID <- seq.int(nrow(result))

result <- result %>% 
  mutate(gcs=paste(lat,long))

#There is no missing values for titles, nor description
#But there are some empty title and description, so I am deleting empty titles.
result <- result[!(result$title==""),]

#result "" to NA.
result$sqft[which(result$sqft==" ")] <- NA

#So, for Kijiji, no desc. 
result$source <- as.factor(result$source)
str(result$source)
result_craig <- result %>% filter(source=="Craigslist")
result_kjj <- result %>% filter(source!="Craigslist")
result_kjj$source[which(result_kjj$source=='kijiji')] <- "Kijiji"
# I will replace kijiji to Kijiji, and then start deduplication for that.
summary(result_kjj$source)

#So I've done standardization of source variable, so i will start dedup process for craigslist 
sum(is.na(result_craig$description))# Since no desc value is NA, we will go for title and desc comparision.
sum(is.na(result_craig$lat))#But there are many(ex.471) values with lat, long as NA.

#Let's delete the exact duplicates from the same name "or" the same description
dif.ttl.or.dif.des<- result_craig %>% 
  filter(!duplicated(title)|!duplicated(description)) 

# dif.ttl.and.dif.des<- result_craig %>% 
#   filter(!duplicated(title)&!duplicated(description)) %>% 
#   arrange(lat,long)


#same title
same.title <- result_craig %>% 
  filter(duplicated(title)) %>% arrange(title)

#same desc
same.desc <- result_craig %>% 
  filter(duplicated(description)) %>% arrange(description)
same.desc <- same.desc[!is.na(same.desc$description),]

#same title and different description
same.ttl.diff.desc <- same.title %>% 
  filter(!(ID%in%same.desc$ID))

same.ttl.same.desc <- same.title %>% 
  filter((ID%in%same.desc$ID))
#Let A subset that has different title,
#Let B subset that has different description,
#Let c subset that has different location.

#Let's make subset B-A-C:same location with same title, different description
#and name it as temp:same title, dif desc, same location

temp <- same.ttl.diff.desc %>% 
  filter(duplicated(gcs))


temp <- temp[!is.na(temp$lat),]
temp <- temp[!is.na(temp$long),]

#B-(A∪C): temp



#Excluding B-(A∪C)
#same location with same title, different description is excluded.
excl.same.ttl.same.loc.dif.des <- dif.ttl.or.dif.des %>% 
  filter(!(ID%in%temp$ID)) %>% 
  arrange(lat,long)


same.desc.diff.ttl <- same.desc %>% 
  filter(!(ID%in%same.title$ID)) %>% 
  arrange(description) 

#So many ,,,, description makes it confused, so will delete them.
desc.temp <- gsub(","," ",same.desc.diff.ttl$description)
desc.temp <- gsub("\n"," ",same.desc.diff.ttl$description)
same.desc.diff.ttl<- same.desc.diff.ttl[grep("\\b \\b", desc.temp),] %>% arrange(lat)

#Let's remove this part.
same.desc.diff.ttl.same.loc <- same.desc.diff.ttl %>% filter(duplicated(gcs))
same.desc.diff.ttl.same.loc <- same.desc.diff.ttl.same.loc[!is.na(same.desc.diff.ttl.same.loc$long),]

#it's removing data with two variables having same values.
excl.same.desc.same.loc.dif.ttl <-  excl.same.ttl.same.loc.dif.des%>% 
  filter(!(ID%in%same.desc.diff.ttl.same.loc$ID))
#So we have excl.same.desc.same.loc.dif.ttl data frame!

#Let's check if the duplicates candidates have same title!
excl.same.desc.same.loc.dif.ttl %>% filter(ID==3699) %>% select(title)==excl.same.desc.same.loc.dif.ttl %>% filter(ID==2213)%>% select(title)

#Let's delete data set having same title, gcs, rooms and price.
excl.same.ttl.gcs.rms.sqft<- excl.same.desc.same.loc.dif.ttl %>% 
  filter(!duplicated(title)|!duplicated(gcs)|!duplicated(rooms)|!duplicated(sqft)|!duplicated(location)) %>% arrange(title)

val.excl.excl.same.ttl.gcs.rms.sqft <- excl.same.desc.same.loc.dif.ttl %>% filter(!(ID%in%excl.same.ttl.gcs.rms.sqft$ID))
excl.same.ttl.gcs.rms.sqft$description <- gsub(",","",excl.same.ttl.gcs.rms.sqft$description)
excl.same.ttl.gcs.rms.sqft$ti = substr(excl.same.ttl.gcs.rms.sqft$title, 1, 5)
excl.same.ttl.gcs.rms.sqft$lt = substr(excl.same.ttl.gcs.rms.sqft$lat, 4, 7)
excl.same.ttl.gcs.rms.sqft$lg = substr(excl.same.ttl.gcs.rms.sqft$long, 6, 9)

crag.rpairs <- RLBigDataDedup(excl.same.ttl.gcs.rms.sqft,blockfld = c('ti','lt','lg'),exclude = c('address','city','country','date','province','lat','long','source',"url","inSurrey",'ID','ti','lt','lg'),
                              strcmp=c('title','description'),strcmpfun = "jarowinkler")
summary(crag.rpairs)

crag.rpairs=emWeights(crag.rpairs)

#hist(rpairs$Wdata, plot=F)
#Error in rpairs$Wdata : $ operator not defined for this S4 class
# getPairs(rpairs,30,20)
summary(crag.rpairs)
#crag.rpairs=emClassify(crag.rpairs, threshold.upper=0, threshold.lower=-26)
crag.possibles <- getPairs(crag.rpairs)
summary(crag.rpairs)
#View(crag.possibles)
crag.links=getPairs(crag.rpairs,single.rows = T)

###########Result.Kijiji############
#View(result_kjj)

kjj.rpairs <- RLBigDataDedup(result_kjj,blockfld = c('location'),exclude = c('address','city','country','date','description','lat','long', 'province','rooms','sqft','source',"url","inSurrey",'ID','gcs'),
                             strcmp=c('title'),strcmpfun = "jarowinkler")
summary(kjj.rpairs)
kjj.rpairs=emWeights(kjj.rpairs)
summary(kjj.rpairs)
#kjj.rpairs=emClassify(kjj.rpairs, threshold.upper=0, threshold.lower=-26)
kjj.possibles <- getPairs(kjj.rpairs)
summary(kjj.rpairs)
#View(kjj.possibles)
kjj.links=getPairs(kjj.rpairs,single.rows = T)

#####Aggregating kijiji and craiglist #######

June_RL_cleaned_crag <-  excl.same.ttl.gcs.rms.sqft%>% 
  filter(!ID%in%c(crag.links$id.2)) %>% select(-c(gcs,ti,lt,lg))
June_RL_cleaned_kjj <-  result_kjj%>% 
  filter(!ID%in%c(kjj.links$id.2)) %>% select(-c(gcs))

June_RL_cleaned<- rbind(June_RL_cleaned_crag,June_RL_cleaned_kjj)
crag.rpairs %>% select(ti)

crag.links_for_Zhe=getPairs(crag.rpairs)
kjj.links_for_Zhe=getPairs(kjj.rpairs)
crag.links_for_Zhe=crag.links_for_Zhe %>% select(-c(ti,lt,lg))
candidate_links_for_Zhe <-rbind(crag.links_for_Zhe,kjj.links_for_Zhe)

####### re dedup for aggregated data ########
June_RL_cleaned$ti = substr(June_RL_cleaned$title, 1, 5)
June_RL_cleaned$lt = substr(June_RL_cleaned$lat, 4, 6)
June_RL_cleaned$lg = substr(June_RL_cleaned$long, 6, 8)
June_RL_cleaned <- June_RL_cleaned %>% 
  mutate(gcs=paste(lat,long))
ag.rpairs <- RLBigDataDedup(June_RL_cleaned,blockfld = c('ti','lt','lg'),exclude = c('address','city','country','date','province','lat','long','source',"url","inSurrey",'ID','ti','lt','lg'),
                            strcmp=c('title','description'),strcmpfun = "jarowinkler")
summary(ag.rpairs)
ag.rpairs=emWeights(ag.rpairs)
summary(ag.rpairs)
ag.possibles <- getPairs(ag.rpairs)
View(ag.possibles)
summary(ag.rpairs)
ag.links=getPairs(ag.rpairs,single.rows = T)

June_RL_cleaned <-  June_RL_cleaned%>% 
  filter(!ID%in%c(ag.links$id.2)) %>% select(-c(gcs,ti,lt,lg))

ag.links_for_Zhe=getPairs(crag.rpairs)
ag.links_for_Zhe=ag.links_for_Zhe %>% select(-c(ti,lt,lg))
#
candidate_links_for_Zhe <-rbind(candidate_links_for_Zhe,ag.links_for_Zhe)


#/Users/hyeongcheolpark/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets
#Save dif.ttl.or.dif.gcs csv and same.ttl.and.same.csv. 
write.csv(June_RL_cleaned, file = "/Users/hyeongcheolpark/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/Aggregated_Clean_20180809_val.csv")
write.csv(candidate_links_for_Zhe, file = "/Users/hyeongcheolpark/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/Aggregated__Duplicated_July_20180809_val.csv")

