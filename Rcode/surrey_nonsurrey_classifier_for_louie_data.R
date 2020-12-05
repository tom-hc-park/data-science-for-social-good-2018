if (!require(tidyverse)) install.packages("tidyverse")
library("tidyverse")


#Load data set
s<-getwd()

datapath<-paste(s,"/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/July_Clean_20180808.csv",sep = "")
#If you cannot load the raw dataset, you need to set it by yourself by matching the csv file name.
result <- read.csv(file=datapath,header=T,stringsAsFactors = FALSE)

#Arrangnig the dataset by title.
result<- result %>% 
  arrange(description)

#Adding index cuz the rowname is not functioning very well.
result$ID <- seq.int(nrow(result))

#There is no missing values for titles, nor description
#But there are some empty title and description, so I am deleting empty titles.
result <- result[!(result$title==""),]


#Let's make a function for the data spliting.
a.regional.data <- function(name){
  
  surrey_title_list <- gregexpr(pattern=name, result$title)
  
  index_surrey_title <- c()
  for (i in 1:nrow(result)) {
    
    if(surrey_title_list[[i]][1]!=-1)
    {index_surrey_title <- c(index_surrey_title,i)}
  }
  index <- c(index_surrey_title)
  index <- index[!duplicated(index)]
  return(result[index,])
}
# a.regional.data function!

#This is to let the function deal with a vector with multiple region names.
subset.data <- function(x) {
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
  complementary.index <- result$ID[-sort(combine(index1, index2))[!duplicated(sort(combine(index1, index2)))]]
  complementary.data <- result[complementary.index,]
  #print(deparse(substitute(vector1))) When you debuging, run inside of a mold, line by line, print things on each step.
  x[[deparse(substitute(vector1))]]=dt1 # Convert a name of a variable to a character(string)
  x[[deparse(substitute(vector2))]]=dt2
  x[["complementary.data"]] = complementary.data
  x[["confusing.data"]] = confusing.data
  return(x)
}


#Surrey
surrey.region <- c("halley","uildford","leetwood","estminster", "ewton","loverdale","urrey","ity centre")

non.surrey.region <- c("hite rock","ission","sawwassen","elta")
# non.surrey.data<- subset.data(non.surrey.region)

test <- classifier(surrey.region, non.surrey.region)

surrey.region.data <- rbind(test[[1]],test[[3]],test[[4]])
non.surrey.region.data <- test[[2]]


filename<-paste(s,"/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/temp.csv",sep = "")
write.csv(surrey.region.data,file=filename)
