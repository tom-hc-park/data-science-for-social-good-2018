if (!require(mice)) install.packages("mice")
if (!require(VIM)) install.packages("VIM")
if (!require(dplyr)) install.packages("dplyr")
if (!require(caret)) install.packages("caret")
library (caret)
library (MASS)
library (dplyr)
library("dplyr")
select <- dplyr::select
s<-getwd()
datapath1<-paste(s,"/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/1000samples_20180815_labelledJA.csv",sep = "")
dat1 <- read.csv(file=datapath1,header=T,stringsAsFactors = FALSE,na.strings = c("","NA"))

dat1$sqft[dat1$sqft<50] <- NA#trim nonsense sqft

hist(dat1$price)# trim the outlier prices such as 1$ or 1111111111$
trim <- function(x){
  quantiles <- quantile( x, c(0.01, .99 ),na.rm = T )
  x[ x < quantiles[1] ] <- quantiles[1]
  x[ x > quantiles[2] ] <- quantiles[2]
  x
}
x=trim(dat1$price)
dat1$price=x
hist(dat1$price)
summary(dat1$price)# Or you can set some threshold like less than 200$  or more than 30000$

dat1$X <- NULL# Sometimes there happens to be some weird variables, usually their name is X, X.1, or description.1
dat1$X.1 <- NULL
dat1$description.1 <- NULL

dat1=dat1[!is.na(dat1$Category),] #Remove the NA category.

dat2_for_mice <- dat1 %>% dplyr::select(lat,long,price,rooms,Category) #You pick the variables to run mice. 
dat2_for_none_mice <- dat1 %>% dplyr::select(-c(lat,long, price,rooms,Category)) #It should be complementary set
tempData2 <- mice(dat2_for_mice,m=10,maxit=50,meth='pmm',seed=1) #Never change seed, for the sake of reproductivity
imputated_data <- complete(tempData2,i) #This will give you the ith imputated data set.
dat2_done <- cbind(imputated_data,dat2_for_none_mice) #This will give you the filled out data set including all the original variables.
#This is how to save the imputated data set into a csv.
write.csv(dat2_done, 
           file = "/Users/hyeongcheolpark/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/Imputated_data_m_1_20180822.csv")

###The codes under is for the checking whether the assumption of mice is holding or not, I will just leave it here.

# pMiss <- function(x){sum(is.na(x))/length(x)*100}#brief understaing of the missing values situation
# # dat2=dat1 %>% dplyr::select(lat,long, price,rooms,sqft,newCategory,split,biCategory)
# apply(dat2,2,pMiss)#too many missing values, especially rooms, sqft
# apply(dat2,1,pMiss)#Also, rooms are categorical, and the article says factor(categorical) variable is not suitable for MICE
# 
# 
# ################# graphs for missing values ######################
# library(mice)
# md.pattern(dat2)
# #md.pattern(dat3)
# 
# library(VIM)
# aggr_plot <- aggr(dat2, col=c('navyblue','red'), numbers=TRUE, sortVars=TRUE, labels=names(dat2), cex.axis=.7, gap=1, ylab=c("Histogram of missing data","Pattern"))
# 
# #lat, long, price,rooms,sqft,Category
# marginplot(dat2[c("rooms","price")])#Not MCAR, but MAR? the boxplots are looking different
# marginplot(dat2[c("rooms","sqft")]) # MAR ish
# marginplot(dat2[c("price","sqft")])
# marginplot(dat2[c("price","lat")])


