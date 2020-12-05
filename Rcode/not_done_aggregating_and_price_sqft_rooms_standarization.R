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
#If you cannot load the raw dataset, you need to set it by yourself by matching the csv file name.
s<-getwd()
datapath1<-paste(s,"/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/Louie_Clean_20180718.csv",sep = "")
datapath2<-paste(s,"/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/June_Clean_20180718.csv",sep = "")
datapath3<-paste(s,"/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/July_Clean_20180718.csv",sep = "")
dat1 <- read.csv(file=datapath1,header=T,stringsAsFactors = FALSE,na.strings = c("","NA"))
dat2 <- read.csv(file=datapath2,header=T,stringsAsFactors = FALSE,na.strings = c("","NA"))
dat3 <- read.csv(file=datapath3,header=T,stringsAsFactors = FALSE,na.strings = c("","NA"))

dat1$inSurrey <- NULL
dat2$inSurrey <- NULL
dat3$inSurrey <- NULL

dat1$X <- NULL
dat2$X <- NULL
dat3$X <- NULL

dat1$ID <- NULL
dat2$ID <- NULL
dat3$ID <- NULL

aggregated_dat <-rbind(dat1,dat2)
aggregated_dat <-rbind(aggregated_dat,dat3)

temp <- gsub("/","",aggregated_dat$rooms)
temp <- gsub("br","",temp)
temp <- gsub("bedroom","",temp)
temp <- gsub(" ","",temp)
temp <- gsub("den","",temp)
temp <- gsub("bachelor","1",temp)

#to remove sqft values on the rooms variable.
temp[grep("ft", temp)] <- NA

aggregated_dat$rooms <- as.factor(temp)

temp_sqft <- gsub("/","",aggregated_dat$sqft)
temp_sqft <- gsub("ft","",aggregated_dat$sqft)
temp_sqft <- as.numeric(temp_sqft)

aggregated_dat$sqft <- temp_sqft

temp_price <- gsub("$","",aggregated_dat$price)
summary(temp_price)
str(temp_price)
temp_price <- as.numeric(temp_price)


aggregated_dat$price <- temp_price

str(aggregated_dat)

as.date

write.csv(aggregated_dat, file = "/Users/hyeongcheolpark/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/temp.csv")

