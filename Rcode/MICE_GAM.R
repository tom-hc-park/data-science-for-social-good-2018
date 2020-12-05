if (!require(mice)) install.packages("mice")
if (!require(dplyr)) install.packages("dplyr")
if (!require(caret)) install.packages("caret")
if (!require(mgcv)) install.packages("mgcv")
library (mgcv)
library (caret)
library (mice)
library (dplyr)
##mode
Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}
##

select <- dplyr::select
complete <- mice::complete
s<-getwd()
datapath1<-paste(s,"/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/1000samples_20180815_labelledJA.csv",sep = "")
dat1 <- read.csv(file=datapath1,header=T,stringsAsFactors = FALSE,na.strings = c("","NA"))


#Delete unnecesary variables drived from GIS, or manual labeling.
dat1$X <- NULL
dat1$X.1 <- NULL
dat1$description.1 <- NULL

dat1=dat1[!is.na(dat1$Category),]

#####

#####

dat1$newCategory <- dat1$Category
dat1$newCategory[dat1$Category<3] <-0
dat1$newCategory[dat1$Category>=3&dat1$Category<4] <-1
dat1$newCategory[dat1$Category>=4&dat1$Category<5] <-2 #1,2 can be aggregated 

dat1$biCategory <- dat1$newCategory
dat1$biCategory[dat1$bi==2] <-1

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
summary(dat1$price)

pMiss <- function(x){sum(is.na(x))/length(x)*100}#brief understaing of the missing values situation
# dat2=dat1 %>% dplyr::select(lat,long, price,rooms,sqft,newCategory)
#dat2 =dat2 %>% mutate(label=newCategory) %>% select(-newCategory)
apply(dat2,2,pMiss)#too many missing values, especially rooms, sqft
apply(dat2,1,pMiss)#Also, rooms are categorical, and the article says factor(categorical) variable is not suitable for MICE


################# graphs for missing values ######################
library(mice)
md.pattern(dat2)
#md.pattern(dat3)

library(VIM)
aggr_plot <- aggr(dat2, col=c('navyblue','red'), numbers=TRUE, sortVars=TRUE, labels=names(dat2), cex.axis=.7, gap=1, ylab=c("Histogram of missing data","Pattern"))

#lat, long, price,rooms,sqft,Category
marginplot(dat2[c("rooms","price")])#Not MCAR, but MAR? the boxplots are looking different
marginplot(dat2[c("rooms","sqft")]) # MAR ish
marginplot(dat2[c("price","sqft")])
marginplot(dat2[c("price","lat")])

######################################  GAM model for inference###############################
#Function can be for logit, addictive model, random forest, etc.
test_error_ftn <- function(data,m,p,seed) {
  dat2 = dat1 %>% select(lat,long, price,rooms,sqft,newCategory)
  tempData2 <- mice(dat2,m=m,maxit=50,meth='pmm',seed=seed)
  model_list_full<- dat_list <- model_list <-pred <- list()
  test_accuracy <- c()
  beta_df <- beta_df_full <- c()
  beta_var_df <- beta_var_df_full<-  c()
  for (i in 1:m){ 
    data=complete(tempData2,i)
    #train/test data set splitted by stratified sampling
    data$index=seq(1:nrow(data))
    if (i==1) {
      set.seed(seed)
      test_set <- data %>%group_by(newCategory) %>%sample_frac(1-p)
      index_test=test_set$index
      training_set <- data %>% filter(!index%in%index_test)
      } else {
        test_set <- data %>% filter(index%in%index_test)
        training_set <- data %>% filter(!(index%in%index_test))}
    dat_list[[i]] <- list(test_set,training_set)
    model_list[[i]] <-gam(formula=list(newCategory~s(lat,long)+price+rooms+sqft,~s(lat,long)+price+rooms+sqft),family=multinom(K=2),data=training_set)
    pred[[i]] <- predict(model_list[[i]], newdata=test_set, type="response")
    pred[[i]]=as.data.frame(pred[[i]]) %>% dplyr::mutate(pred=apply(pred[[i]], MARGIN =1, FUN=which.max)-1)
    test_accuracy <- c(test_accuracy,sum(test_set$newCategory==pred[[i]][,4])/nrow(test_set))
    temp_beta <- summary(model_list[[i]])$p.coeff
    beta_df <- rbind(beta_df,temp_beta)
    temp_beta_var <- as.data.frame(t(summary(model_list[[i]])$se))
    temp_beta_var <-temp_beta_var %>% select("(Intercept)","price","rooms","sqft","(Intercept).1","price.1","rooms.1","sqft.1")
    beta_var_df <- rbind(beta_var_df,temp_beta_var)
    beta_var_df_square <-beta_var_df^2
    
    #Below is to get the full model from full data set.
    model_list_full[[i]] <- gam(formula =list(newCategory~s(lat,long)+price+rooms+sqft,~s(lat,long)+price+rooms+sqft),family=multinom(K=2),data=data)
    temp_beta_full <- summary(model_list_full[[i]])$p.coeff
    beta_df_full <- rbind(beta_df_full,temp_beta_full)
    temp_beta_var <- as.data.frame(t(summary(model_list_full[[i]])$se))
    temp_beta_var <-temp_beta_var %>% select("(Intercept)","price","rooms","sqft","(Intercept).1","price.1","rooms.1","sqft.1")
    beta_var_df_full <- rbind(beta_var_df_full,temp_beta_var)
    beta_var_df_square_full <-beta_var_df_full^2
    }
  major_pred=c()
  for (i in 1:m) major_pred=cbind(major_pred,pred[[i]][,4])
  #ac=as.vector(apply(major_pred,1,Mode))
  major_pred=as.data.frame(major_pred)
  major_pred$result=apply(major_pred,1,Mode)
  majority_test_accuracy <- sum(major_pred$result==test_set$newCategory)/nrow(test_set)
  beta_average <- apply(beta_df,2,mean)
  Vw<- (1/m)*apply(beta_var_df^2,2,sum)
  p.j_p.bar <- c()
  for(i in 1:nrow(beta_df)) p.j_p.bar <- rbind(p.j_p.bar,beta_df[i,]-beta_average)
  Vb <- (1/(m-1))*apply(p.j_p.bar^2,2,sum)
  V.p.bar <- Vw+Vb*(1+(1/m))
  s.e.V.p.bar <- sqrt(V.p.bar)
  beta.df <- rbind(beta_average,s.e.V.p.bar)
  
  #For full model
  beta_average_full <- apply(beta_df_full,2,mean)#beta_df_full, beta_var_df_full, beta_var_df_square_full
  Vw_full<- (1/m)*apply(beta_var_df_full^2,2,sum)
  p.j_p.bar_full <- c()
  for(i in 1:nrow(beta_df_full)) p.j_p.bar_full <- rbind(p.j_p.bar_full,beta_df_full[i,]-beta_average_full)
  Vb_full <- (1/(m-1))*apply(p.j_p.bar_full^2,2,sum)
  V.p.bar_full <- Vw_full+Vb_full*(1+(1/m))
  s.e.V.p.bar_full <- sqrt(V.p.bar_full)
  beta.df_full <- rbind(beta_average_full,s.e.V.p.bar_full)
  
  output=list("beta.df"=beta.df,"beta.df_full"=beta.df_full,"data_list"=dat_list, "model_list_full"=model_list_full,"prediction_result"=pred,"test_accuracy"=test_accuracy,"majority_test_accuracy"=majority_test_accuracy,
              'predicted_values'=major_pred$result)
  }

list_output <- test_error_ftn(dat1,10,0.8,1)
summary(list_output[[4]][[1]])
list_output[[5]]
# To calculate P(>|z|)
partial.est <- list_output[[1]] #for estimates of training data
full.est <- list_output[[2]] # For the whole data's estimates

z_part <- a[1,]/a[2,] #z value(partial)
z_full <- b[1,]/b[2,] #z value(whole)

#z_values_table
z_values=rbind(z_part,z_full)

#define a function for P(>|z|)
p_value <- function(x){
  if (sign(x)==-1) {
    return(pnorm(x)*2)
  } else {
    return(pnorm(-x)*2)
  }
}

# p-value(partial)
names=names(z_part)
z_part=unname(z_part, force = FALSE)
z_part=as.matrix(z_part)
str(z_part)
p_part <- apply(z_part, 1,z_value)
# z_value(z_part[8])
z_part=as.vector(z_part)
names(z_part)=names
names(p_part)=names

# p-value(full)
z_full=unname(z_full, force = FALSE)
z_full=as.matrix(z_full)
str(z_full)
p_full <- apply(z_full, 1,z_value)
#z_value(z_full[8])
z_full=as.vector(z_full)
names(p_part)=names
#Here comes the p-value table.
p_values=rbind(p_part,p_full)

#Contour plots
plot(list_output[[4]][[1]],pages=1) #weird contour
gam.check(list_output[[4]][[1]]) #The 4 plots
plot(list_output[[4]][[1]],rug = FALSE, se = FALSE, n2 = 80, main = "gam n.4 with te()") #contour
plot(list_output[[4]][[1]], pages=1,rug = T, se = F, n2 = 80) #contour

vis.gam(list_output[[4]][[1]], view=c("lat","long"), n.grid = 50, theta = 35, phi = 32, zlab = "",
        ticktype = "detailed", color = "topo", main = "t2(D, W)")

vis.gam(list_output[[4]][[1]], view=c("lat","long"), main = "t2(D, W)", plot.type = "contour",
        color = "terrain", contour.col = "black", lwd = 2)




#For future work, some variations included.######################################################################################

# latest=function(data,p){
#   testdat=dat1 %>% filter(date%in%c(dat1$date[grep("2018-07",dat1$date)])) %>% arrange(desc(date))
#   testdat=testdat[1:floor(p*nrow(dat1)),] %>% mutate(split="test")
#   traindat=dat1 %>% filter(!url%in%c(testdat$url)) %>% mutate(split="training")
#   dat1=rbind(testdat,traindat)
#   rm(testdat,traindat)
#   dat2 <- dat1 %>% dplyr::select(lat,long, price,rooms,sqft,newCategory,split,biCategory)
#   return(dat2)
# }
#If it is simple random sampling, then I have to have a k different folds. carret package should be used in here I guess.
# SRSWOR=function(data,p){
#   set.seed(123)
#   smp_size <- floor(p * nrow(dat1))
#   dat1_ind <- sample(seq_len(nrow(dat1)), size = smp_size)
#   dat1$ID <- seq.int(nrow(dat1))
#   testdat=dat1[-dat1_ind,] %>% mutate(split="test")
#   traindat=dat1[dat1_ind,] %>% mutate(split="training")
#   dat1=rbind(testdat,traindat) %>% dplyr::select(-ID)
#   rm(testdat,traindat)
#   dat2 <- dat1 %>% select(lat,long, price,rooms,sqft,newCategory,split,biCategory)
#   return(dat2)
# }


# SRSWOR_list=function(data,p,k){
#   dat2 = dat1 %>% select(lat,long, price,rooms,sqft,newCategory,biCategory)%>% mutate(index=seq(1:nrow(dat1)))
#   folds<-createFolds(dat2$index,k)
#   list_of_dat_folds=list(dat2,folds)
#   return(list_of_dat_folds)
# }


###########################Short version of choosing the method of sampling function#####################################
# sampling_method=function(data,random,p) {
#   if (random==T) {SRSWOR_list(data,p)} 
#   else if (random==F) {latest(data,p)}
#   else print("Only T or F")
#   }


###############################Function of ...#######################################################
#Function can be for logit, addictive model, random forest, etc.
# test_error_ftn <- function(data,m,random,p,seed,model,sqft,k) {
#   if (random==F){
#   dat2=sampling_method(data,random,p)
#   if (sqft==T) {}
#   else if (sqft==F) dat2 =dat2 %>% select(-sqft)
#   tempData2 <- mice(dat2,m=m,maxit=50,meth='pmm',seed=seed)
#   # we don't need biCategory for imputation? But I need the biCategory for gam2. How can I delete that?
#   dat_list <- model_list <-pred <- list()
#   test_accuracy <- c()
#   for (i in 1:m) {
#     dat_list[[i]]=complete(tempData2,i)
#     train1=dat_list[[i]] %>% filter(split=='training')
#     gam1 <- gam(as.factor(biCategory)~s(lat ,long)+price+rooms+sqft, family = "binomial",data=train1)
#     gam2 <- gam(as.factor(newCategory)~s(lat,long)+price+rooms+sqft, family = "binomial",data=train1[train1$newCategory!=0,])
#     model_list[[i]]=list(gam1,gam2)
#     test1=dat_list[[i]] %>% filter(split=='test')# %>% dplyr::select(-biCategory,-newCategory)
#     pred1 <- predict(model_list[[i]][[1]], newdata=test1, type="response")
#     pred2 <- predict(model_list[[i]][[2]], newdata=test1, type="response")
#     p0 <- (1-pred1)
#     p2 <- pred2 * pred1
#     p1 <- (1-pred2) * pred1
#     prob <- data.frame("p0"=p0,"p1"=p1,"p2"=p2)
#     prob=prob %>% mutate(pred=apply(prob, MARGIN =1, FUN=which.max)-1)#Okay, so I have the prob and the pred
#     pred[[i]] <- prob
#     test_accuracy[i] <- sum(test1$newCategory==prob$pred)/nrow(test1)#Let's so compare the prediction error (test error)
#     #get the predictive value
#     #obtain the test error (prediction accuracy)
#     #average the prediction accuracy
#     #you are in a a for loop
#   }
#   test_error=sum(test_accuracy)/m
# 
#     tmp_agg_test_prob <- (Reduce('+',pred)/10)[,-4] # mean
#     tmp_agg_test_label <- as.vector(apply(tmp_agg_test_prob, MARGIN =1, FUN=which.max)-1)
#     aggregated_test_error <- sum(test1$newCategory==tmp_agg_test_label)/nrow(test1)
#     mylist=list('data'=data,'averaged_test_error'=test_error,"test_accuracy_vector"=test_accuracy,
#                 "dat_list"=dat_list,'model_list'=model_list,"pred"=pred,
#                 'aggregated_test_error'= aggregated_test_error)
#   
#   print(test_error)
#   return(mylist)}
#   ####################Randomly selecting -> k fold and MICE and run 
#   else if (random==T) {
#     list_of_dat_folds=sampling_method(data,random,p)
#     if (sqft==T) {}
#     else if (sqft==F) dat2 =dat2 %>% select(-sqft)
#     tempData2 <- mice(list_of_dat_folds[[1]],m=m,maxit=50,meth='pmm',seed=seed)
#     #######start of the K fold * MICE * modeling
#     dat_list <- model_list <-pred <- list()
#     test_accuracy <- c()
#     for (i in 1:m) {
#       #remember you have (k)folds=list_of_dat_folds[[2]]. 
#       dat_list[[i]]=complete(tempData2,i)
#       #train1=dat_list[[i]] %>% filter(split=='training')
#       for (j in 1:k) {
#         gam1 <- gam(as.factor(biCategory)~s(lat ,long)+price+rooms+sqft, family = "binomial",data=train1)
#         gam2 <- gam(as.factor(newCategory)~s(lat,long)+price+rooms+sqft, family = "binomial",data=train1[train1$newCategory!=0,])
#         model_list[[i]]=list(gam1,gam2)
#         test1=dat_list[[i]] %>% filter(split=='test')# %>% dplyr::select(-biCategory,-newCategory)
#         pred1 <- predict(model_list[[i]][[1]], newdata=test1, type="response")
#         pred2 <- predict(model_list[[i]][[2]], newdata=test1, type="response")
#         p0 <- (1-pred1)
#         p2 <- pred2 * pred1
#         p1 <- (1-pred2) * pred1
#         prob <- data.frame("p0"=p0,"p1"=p1,"p2"=p2)
#         prob=prob %>% mutate(pred=apply(prob, MARGIN =1, FUN=which.max)-1)#Okay, so I have the prob and the pred
#         pred[[i]] <- prob
#         test_accuracy[i] <- sum(test1$newCategory==prob$pred)/nrow(test1)#Let's so compare the prediction error (test error)
#         #get the predictive value
#         #obtain the test error (prediction accuracy)
#         #average the prediction accuracy
#         #you are in a a for loop
#       }
#       
#     }
#     test_error=sum(test_accuracy)/m
#     
#     tmp_agg_test_prob <- (Reduce('+',pred)/10)[,-4] # mean
#     tmp_agg_test_label <- as.vector(apply(tmp_agg_test_prob, MARGIN =1, FUN=which.max)-1)
#     aggregated_test_error <- sum(test1$newCategory==tmp_agg_test_label)/nrow(test1)
#     mylist=list('data'=data,'averaged_test_error'=test_error,"test_accuracy_vector"=test_accuracy,
#                 "dat_list"=dat_list,'model_list'=model_list,"pred"=pred,
#                 'aggregated_test_error'= aggregated_test_error)
#     
#     print(test_error)
#     return(mylist)
#     #mylist=list('data'=data,'averaged_test_error'=test_error,"test_accuracy_vector"=test_accuracy,"dat_list"=dat_list,'model_list'=model_list,"pred"=pred)
#   }}
# 
# 
# 
# myftn=test_error_ftn(data=dat1,m=10,random =F,p=0.8,seed=12)# Test line
# myftn$averaged_test_error
# myftn$aggregated_test_error
# #I should rerun the all training to all the data set .
