if (!require(dplyr)) install.packages("dplyr")
library("dplyr")

s<-getwd()
datapath1<-paste(s,"/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/1000samples_20180813_merged.csv",sep = "")
datapath2<-paste(s,"/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/1000samples_20180810-JL_partial_labels.csv",sep = "")

dat1 <- read.csv(file=datapath1,header=T,stringsAsFactors = FALSE,na.strings = c("","NA")) 
dat1$X <- NULL
dat1$X.1 <- NULL
dat2 <- read.csv(file=datapath2,header=T,stringsAsFactors = FALSE,na.strings = c("","NA"))
dat2 <- dat2 %>% select(url,Label_0.entire_1.part,Label_0.entire_1.suite_2.room)

total <- left_join(dat1,dat2,by="url")

write.csv(total, file = "/Users/hyeongcheolpark/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/1000samples_20180810_merged.csv")
