# if (!require(stringdist)) install.packages("stringdist")
# if (!require(PASWR)) install.packages("PASWR")
# if (!require(DescTools)) install.packages("DescTools")
# if (!require(RecordLinkage)) install.packages("RecordLinkage")
# library("RecordLinkage")
# library(DescTools)
# library (MASS)
# library(dplyr)
# library(stringdist)
# library(PASWR)


#Load data set
s<-getwd()
datapath1<-paste(s,"/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/Louie_Clean_20180808.csv",sep = "")
datapath2<-paste(s,"/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/Aggregated_Clean_20180809_val.csv",sep = "")

dat1 <- read.csv(file=datapath1,header=T,stringsAsFactors = FALSE,na.strings = c("","NA"))
dat2 <- read.csv(file=datapath2,header=T,stringsAsFactors = FALSE,na.strings = c("","NA"))
dat1 <- dat1 %>% select(-c(X,ID))
dat2 <- dat2 %>% select(-c(X,X.1,ID,inSurrey))


dat1$from <- 'Louie'
dat2$from <- 'June_and_July'
aggreated_dat <-rbind(dat1,dat2)
aggreated_dat$ID <- seq(1:nrow(aggreated_dat))
set.seed(1)
samples <- sample_n(aggreated_dat, 1000)
write.csv(samples, file = "/Users/hyeongcheolpark/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/1000samples_20180810.csv")
