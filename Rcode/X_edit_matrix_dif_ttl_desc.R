# library(devtools)
# devtools::install_github("hadley/tidyverse")
library(dplyr)
# install_github("https://github.com/markvanderloo/stringdist")
library(stringdist)


#Load data set
s<-getwd()
datapath<-paste(s,"/raw_listing.csv",sep = "")
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

#Let's delete the exact duplicates from the same name "or" the same description
dif.ttl.or.dif.des<- result %>%
  filter(!duplicated(title)|!duplicated(description)) %>%
  arrange(lat,long)%>%
  select(lat, long, title, description,date:ID)
#ID first, removing "" next result goes to the dataset, and we get the matrix.


# temp <- dif.ttl.or.dif.des[1:10,]
dif.ttl.or.dif.des <- dif.ttl.or.dif.des %>% 
  mutate(strings=paste(lat,long,title,description))

start.time <- Sys.time()
edit.matrix <- stringdistmatrix(dif.ttl.or.dif.des$strings,dif.ttl.or.dif.des$strings)
end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken
save(edit.matrix,file="edit_dist_matrix.RData")
save(time.taken,file="time_taken.RData")
