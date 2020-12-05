if (!require(randomForest)) install.packages("randomForest")
library("randomForest")
library("dplyr")
s<-getwd()
datapath1<-paste(s,"/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/1000samples_20180810-JL_partial_labels_standardized_bedroomscaled.csv",sep = "")
dat1 <- read.csv(file=datapath1,header=T,stringsAsFactors = FALSE,na.strings = c("","NA"))

# total_n=sum(!is.na(dat1$Label_0.entire_1.part))
# dat1 <- dat1[1:total_n,]
set.seed(101)

dat1=dat1 %>% filter(!is.na(rooms) & !is.na(price) & !is.na(sqft))
#Missing value imputation. 
hist(dat1$price)
summary(dat1$price)
dat1$price
k1=100
k2=10000
dat1$price[(dat1$price<k1 | dat1$price>k2)]
dat1$price[(dat1$price<k1 | dat1$price>k2)]=NA
dat1$price

dat1$rooms
dat1$sqft

sum(dat1$Label_0.entire_1.part==1)
dat2=data.frame(index=seq(1:99))

dat1$rooms=dat1$rooms[!is.na(dat1$rooms)]

dat1=dat1 %>% filter(rooms!=NA&sqft!=N&price!=NA)


train=sample(1:nrow(dat1),60)
sample.rf=randomForest(Label_0.entire_1.part ~ price+sqft+rooms , data = dat1 , subset = train)
sample.ef
plot(sample.ef)

oob.err=double(13)
test.err=double(13)

#mtry is no of Variables randomly chosen at each split
for(mtry in 1:13) 
{
  rf=randomForest(medv ~ . , data = Boston , subset = train,mtry=mtry,ntree=400) 
  oob.err[mtry] = rf$mse[400] #Error of all Trees fitted
  
  pred<-predict(rf,Boston[-train,]) #Predictions on Test Set for each Tree
  test.err[mtry]= with(Boston[-train,], mean( (medv - pred)^2)) #Mean Squared Test Error
  
  cat(mtry," ") #printing the output to the console
  
}

test.err

oob.err

matplot(1:mtry , cbind(oob.err,test.err), pch=19 , col=c("red","blue"),type="b",ylab="Mean Squared Error",xlab="Number of Predictors Considered at each Split")
legend("topright",legend=c("Out of Bag Error","Test Error"),pch=19, col=c("red","blue"))