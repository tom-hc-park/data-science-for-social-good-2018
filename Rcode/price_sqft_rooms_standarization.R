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
#datapath1<-paste(s,"/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/1000samples_20180810_labelledJA.csv",sep = "")
datapath1 <- paste(s,"/results/temp/out3.csv", sep="")
# datapath2<-paste(s,"/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/June_Clean_20180718.csv",sep = "")
# datapath3<-paste(s,"/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/July_Clean_20180718.csv",sep = "")
dat1 <- read.csv(file=datapath1,header=T,stringsAsFactors = FALSE,na.strings = c("","NA"))
# dat2 <- read.csv(file=datapath2,header=T,stringsAsFactors = FALSE,na.strings = c("","NA"))
# dat3 <- read.csv(file=datapath3,header=T,stringsAsFactors = FALSE,na.strings = c("","NA"))

#dat1$inSurrey <- NULL
# dat2$inSurrey <- NULL
# dat3$inSurrey <- NULL

dat1$X <- NULL
# dat2$X <- NULL
# dat3$X <- NULL

dat1$ID <- NULL
# dat2$ID <- NULL
# dat3$ID <- NULL

# aggregated_dat <-rbind(dat1,dat2)
# aggregated_dat <-rbind(aggregated_dat,dat3)

temp <- gsub("/","",dat1$rooms)
sum(is.na(temp))
sum(is.na(dat1$rooms))
temp <- gsub("br","",temp)
temp <- gsub("bedroom","",temp)
temp <- gsub(" ","",temp)
temp <- gsub("den","",temp)
temp <- gsub("bachelor","1",temp)
sum(is.na(temp))
#to remove sqft values on the rooms variable.
temp[grep("ft", temp)] <- NA
sum(is.na(temp))

dat1$rooms <- as.factor(temp)

temp_sqft <- gsub("ft","",dat1$sqft)
temp_sqft <- gsub(" ","",temp_sqft)
temp_sqft <- gsub("/","",temp_sqft)
head(temp_sqft)
#str(temp_sqft)
temp_sqft[1]
sum(is.na(temp_sqft))
sum(is.na(dat1$sqft))
temp_sqft_numeric <- as.numeric(temp_sqft)
sum(is.na(temp_sqft_numeric))
dat1$sqft <- temp_sqft_numeric

temp_price <- gsub("\\$","",dat1$price)
temp_price <- gsub(",","",temp_price)
sum(is.na(dat1$price))
sum(is.na(temp_price))
summary(temp_price)
#str(temp_price)
temp_price_corced <- as.numeric(temp_price)
sum(is.na(temp_price_corced))

dat1$price <- temp_price

# levels(dat1$rooms) <- c(levels(dat1$rooms), "1.1")
# dat1$rooms[dat1$rooms == 'privateroom'] <- '1.1'

#str(dat1)

outfile = paste(s, "/results/temp/out4.csv", sep="")
write.csv(dat1, file = outfile)

