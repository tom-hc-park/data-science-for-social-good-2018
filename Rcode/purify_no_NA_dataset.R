#Purify data 
if (!require(dplyr)) install.packages("dplyr")
library("dplyr")

s<-getwd()
datapath1<-paste(s,"/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/1000samples_20180815_labelledJA.csv",sep = "")
dat1 <- read.csv(file=datapath1,header=T,stringsAsFactors = FALSE,na.strings = c("","NA"))

dat1$X <- NULL
dat1$X.1 <- NULL
dat1$description.1 <- NULL

dat2=dat1 %>% filter(!is.na(price)&!is.na(sqft)&!is.na(rooms))
dat3=dat1 %>% filter(!is.na(price)&!is.na(sqft)&!is.na(rooms)&is.na(X.2)&is.na(X.3))

write.csv(dat2, file = "/Users/hyeongcheolpark/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/1000samples_20180815_withstar_labelledJA.csv")
write.csv(dat3, file = "/Users/hyeongcheolpark/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/1000samples_20180815_withoutstar_labelledJA.csv")
