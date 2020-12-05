if (!require(dplyr)) install.packages("dplyr")
library("dplyr")

s<-getwd()
datapath1<-paste(s,"/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/Aggregated_Clean_20180813.csv",sep = "")
dat1 <- read.csv(file=datapath1,header=T,stringsAsFactors = FALSE,na.strings = c("","NA"))

str(dat1)

x=dat1$price
x=as.numeric(x)

x[which(x==max(x))]=NA
x[which(x==min(x))]=NA
x=x[is.na(x)==F]
summary(x)
head(x)
hist(x)
ggplot(dat1, aes(x=price)) + geom_histogram(binwidth=40)
