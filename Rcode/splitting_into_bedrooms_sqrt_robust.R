library(dplyr)
#Load data set
s<-getwd()
substr(s, 1, nchar(s)-5)
datapath<-paste(substr(s, 1, nchar(s)-5),"results/listings-2018-06.csv",sep = "")
#If you cannot load the raw dataset, you need to set it by yourself by matching the csv file name.
result <- read.csv(file=datapath,header=T,stringsAsFactors = FALSE)

#Index added
result$ID <- seq.int(nrow(result))

result$housing_type <- gsub("/","",result$housing_type)

private_index <- grep("\\bprivate room\\b", result$housing_type)
result$sqrt<- result$rooms <- NA
result <- result[!(result$title==""),]



#the dataframe b is for data without the world "private room"
b <- result %>% 
  filter(!as.numeric(row.names(result))%in%private_index) %>% 
  select(ID,housing_type,rooms,sqrt)

br.index.b <- grep("-",b$housing_type,value=FALSE)

b.dash <- b[br.index.b,]
b.dash.list <- strsplit(b.dash$housing_type,"-")
length(b.dash.list)
for (i in 1:length(b.dash.list)) {
  b.dash$rooms[i] <- b.dash.list[[i]][1]
  b.dash$sqrt[i]<- b.dash.list[[i]][2]
}

no.dash.index <-  which(!1:nrow(b)%in%br.index.b)

#Senity check
length(no.dash.index)+length(br.index.b)
#good

b.no.dash <- b[no.dash.index,]

#if there is "ft", then the value goes to sqft.
for (i in 1:nrow(b.no.dash)) {
  if (grepl("ft",b.no.dash$housing_type[i])==TRUE) {
    b.no.dash$sqrt[i] <- b.no.dash$housing_type[i]
  }
  else(b.no.dash$rooms[i] <- b.no.dash$housing_type[i])
}

#ifelse, the value goes to room

#######c is for data with "private rooms" with their values.
c <- result %>% 
  filter(as.numeric(row.names(result))%in%private_index)%>% 
  select(ID,housing_type,rooms,sqrt)

dash.index.c <- grep("-",c$housing_type,value=FALSE)

c.dash <- c[dash.index.c,]
c.dash.list <- strsplit(c.dash$housing_type,"-")
c.dash$rooms <- "private room"
for (i in 1:length(c.dash.list)) {
  c.dash$sqrt[i] <- c.dash.list[[i]][1]
}
#What should I do with this stupid one observations?
#There are some stupid observations on c.dash 
grep("br",c.dash$sqrt)
c.dash$sqrt[100] <- NA
c.dash$sqrt[101] <- NA
c.dash$sqrt[114] <- NA
c.dash$sqrt[135] <- "159ft"
#This is stupid manually changing 

c.no.dash <- c[-dash.index.c,]
c.no.dash$rooms <- "private room"
# c.dash$housing_type <- gsub("\\bprivate room\\b","",c.messed$housing_type)
# c.messed$housing_type <- gsub("-","",c.messed$housing_type)
# c.messed <- c.messed %>% 
#   mutate(sqrt=substr(housing_type,6,9)) %>% 
#   select(ID,rooms,sqrt)

# c.unmessed <- c.unmessed%>% 
#   mutate(sqrt=substr(housing_type,1,6)) %>% 
#   select(ID,rooms,sqrt)
# c.unmessed$sqrt <- gsub("f","",c.unmessed$sqrt)
# c.unmessed$sqrt <- gsub("t","",c.unmessed$sqrt)
#######

result <- result %>% 
  select(-rooms,-sqrt)

result <- merge(result,b.dash,by="ID", all=TRUE)
result <- merge(result,b.no.dash,by="ID", all.x=TRUE)
result$rooms<-paste0(result$rooms.x,result$rooms.y)
result$sqrt<-paste0(result$sqrt.x,result$sqrt.y)
result$rooms <- gsub("NA","",result$rooms)
result$sqrt <- gsub("NA","",result$sqrt)
result <- result %>%
  select(-rooms.x,-rooms.y,-sqrt.x,-sqrt.y,-housing_type.x,-housing_type,-housing_type.y)


c. <- merge(c.dash,c.no.dash,by="ID", all =TRUE)
c.$rooms<-paste0(c.$rooms.x,c.$rooms.y) 
c.$sqrt<-paste0(c.$sqrt.x,c.$sqrt.y) 
c.$rooms <- gsub("NA","",c.$rooms)
c.$sqrt <- gsub("NA","",c.$sqrt)
c. <- c. %>% 
  select(-rooms.x,-rooms.y,-sqrt.x,-sqrt.y,-housing_type.x,-housing_type.y)

result <- merge(result,c.,by="ID", all.x=TRUE)
result$rooms<-paste0(result$rooms.x,result$rooms.y) 
result$sqrt<-paste0(result$sqrt.x,result$sqrt.y) 
result$rooms <- gsub("NA","",result$rooms)
result$sqrt <- gsub("NA","",result$sqrt)
result <- result %>% 
  select(-rooms.x,-rooms.y,-sqrt.x,-sqrt.y)

write.csv(result, file = "/Users/hyeongcheolpark/Desktop/DSSG/gitscripper/DSSG-2018_Housing/data_cleaning/_DeDuplication_On_IDs/2018-06-splitted.csv", append = FALSE, quote = TRUE, sep = ",",
            eol = "\n", na = "NA", dec = ".", row.names = TRUE,
            col.names = TRUE, qmethod = c("escape", "double"),
            fileEncoding = "")

write.csv(result, file = "/Users/hyeongcheolpark/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/2018-06-splitted.csv", append = FALSE, quote = TRUE, sep = ",",
          eol = "\n", na = "NA", dec = ".", row.names = TRUE,
          col.names = TRUE, qmethod = c("escape", "double"),
          fileEncoding = "")

