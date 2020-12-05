if (!require(tidyverse)) install.packages("tidyverse")
library("tidyverse")
library("lubridate")

##Load data set
s<-getwd()
datapath<- paste(s, 'results/temp/out1_2.csv', sep="/")

#For the pipeline
# #datapath<-paste(s,"/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/July_Clean_20180718_withNonSurrey.csv",sep = "")
# #For Aug, Sep data set.
# datapath<-paste(s,"/Desktop/Aug_Sep_clean20181014.csv",sep = "")
# 
# #If you cannot load the raw dataset, you need to set it by yourself by matching the csv file name.
# result <- read.csv(file=datapath,header=T,stringsAsFactors = FALSE)
# result$Unnamed..0 <- NULL #Wierd column deleted
# 
# #Arrangnig the dataset by title.
# result<- result %>%
#   arrange(title)
# 
# #Adding index cuz the rowname is not functioning very well.
# result$ID <- seq.int(nrow(result))
# 
# #There is no missing values for titles, nor description
# #But there are some empty title and description, so I am deleting empty titles.
# result <- result[!(result$title==""),]
# 

#Function for loading in data and preliminary data cleaning (merging code from above)
nonSurrey_setup <- function (path) {
  filepath <- paste(path, sep="")
  result <- read.csv(file=filepath, header=T, stringsAsFactors = FALSE)
  result$Unnamed..0 <- NULL
  result<- result %>% 
    arrange(title)
  result$ID <- seq.int(nrow(result))
  result <- result[!(result$title==""),]
  return(result)
}

#Let's make a function for the data spliting.
#This function gives us data points which has 'name' value on its location, title and description
a.regional.data <- function(name){
  #in location, title and description, catch if a value has 'name' string on it.
  surrey_location_list <- gregexpr(pattern=name, result$location)
  surrey_title_list <- gregexpr(pattern=name, result$title)
  surrey_description_list <- gregexpr(pattern=name, result$description)
  #empty vector to save the index of detected data
  index_surrey_location <- index_surrey_description <- index_surrey_title<-  c()
  # for each variable (location, title, description), save the index into the empty vector for each.
  for (i in 1:nrow(result)) {
    if(surrey_location_list[[i]][1]!=-1)
    {index_surrey_location <- c(index_surrey_location,i)}
    if(surrey_title_list[[i]][1]!=-1)
    {index_surrey_title <- c(index_surrey_title,i)}
    if(surrey_description_list[[i]][1]!=-1)
    {index_surrey_description <- c(index_surrey_description,i)}
  }
  #into one bag of vector put all the indexes. 
  index <- c(index_surrey_location,index_surrey_title,index_surrey_description)
  #delete duplicated index
  index <- index[!duplicated(index)]
  #give me the detected data points.
  index <- sort(index)
  return(result[index,])
}# a.regional.data function: detect a single string from location, title and description.

#This is to let the function deal with a vector with multiple region names.
subset.data <- function(x) {#'x' is a vector with regional names 
  l.result<- lapply(x, a.regional.data)
  temp1 <- l.result[[1]]
  for (i in 1:(length(l.result)-1)) {
    temp1 <- rbind(temp1,l.result[[i+1]])
    
  }
  regional.data <- unique(temp1)
  regional.data <- regional.data %>% arrange(ID)
  return(regional.data)
}
#So we can put more than one regions as arguments of the function.

#Btw, I can pick all of the dataset which contains non surrey regions by doing the same logical things.
#And then there must be an intersect. I will set a intersect dataset, data set A(only surrey), data set B(only nonsurrey),
#and finally a dataset which is not including any of the previous data sets.

#So let's make that as a function.
classifier <- function(vector1,vector2)
{
  x <- list()
  #surrey region subset
  dt1<- subset.data(vector1)
  #non surrey region subset
  dt2 <- subset.data(vector2)
  #intersection subset
  duplicate.index <- dt2$ID
  confusing.data <- dt1 %>% 
    filter(ID %in% duplicate.index)
  #complementary subset
  index1 <- dt1$ID
  index2 <- dt2$ID
  only_nonsurrey <- dt2 %>% 
    filter(!(ID %in% dt1$ID))
  complementary.index <- result$ID[-sort(combine(index1, index2))[!duplicated(sort(combine(index1, index2)))]]
  complementary.data <- result[complementary.index,]
  #print(deparse(substitute(vector1))) When you debuging, run inside of a mold, line by line, print things on each step.
  x[[deparse(substitute(vector1))]]=dt1 # Convert a name of a variable to a character(string)
  x[[deparse(substitute(vector2))]]=dt2
  x[["complementary.data"]] = complementary.data
  x[["confusing.data"]] = confusing.data
  x[["only_nonsurrey"]] = only_nonsurrey
  return(x)
}


#Surrey
surrey.region <- c("halley","uildford","leetwood","estminster", "ewton","loverdale","urrey","ity centre")

non.surrey.region <- c("hite rock","ission","sawwassen","elta","urnaby","angley","oquitlam","DELTA","WHITE ROCK","BURNABY")
# non.surrey.data<- subset.data(non.surrey.region)

result <- nonSurrey_setup(datapath)

test <- classifier(surrey.region, non.surrey.region)

nonsurrey_ID <- test[["only_nonsurrey"]]$ID
surrey_conservative <- result %>% filter(!(ID%in%nonsurrey_ID))

#To make automatic cleaned name for the sake of pipeline.
strn <- date()
strn
year<- substr(strn, 21, 24)
date <- substr(strn, 9, 10)
strn_sys <- Sys.Date()
month <- substr(strn_sys,6,7)
month
suffix <- paste(year,month,date,".csv", sep = "", collapse = NULL)

# setwd("/Users/hyeongcheolpark/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets")
filename<-paste(s, "/results/temp/out2.csv", sep="")

#save csv file.
write.csv(surrey_conservative,file=filename)
