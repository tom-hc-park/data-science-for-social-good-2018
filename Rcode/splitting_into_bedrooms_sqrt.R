library(dplyr)
#Load data set
s<-getwd()
substr(s, 1, nchar(s)-5)
<<<<<<< HEAD
datapath<-paste(substr(s, 1, nchar(s)-5),"rental_crawlers/raw_listing.csv",sep = "")
=======
datapath<-paste(substr(s, 1, nchar(s)-5),"results/listings-2018-06.csv",sep = "")
>>>>>>> June
#If you cannot load the raw dataset, you need to set it by yourself by matching the csv file name.
result <- read.csv(file=datapath,header=T,stringsAsFactors = FALSE)

#Index added
result$ID <- seq.int(nrow(result))

result$housing_type <- gsub("/","",result$housing_type)

private_index <- grep("\\bprivate room\\b", result$housing_type)
result$sqrt<- result$rooms <- NA


<<<<<<< HEAD

=======
#the dataframe b is for data without the world "private room"
>>>>>>> June
b <- result %>% 
  filter(!as.numeric(row.names(result))%in%private_index) %>% 
  select(ID,housing_type,rooms,sqrt)

br.index.b <- grep("br",b$housing_type,value=FALSE)

b.rooms <- b[br.index.b,] %>% 
  mutate(rooms=substr(housing_type,1,2),sqrt=substr(housing_type,8,12)) 

b.rooms$rooms <- gsub("b","",b.rooms$rooms)
b.rooms$sqrt <- gsub("f","",b.rooms$sqrt)
b.rooms$sqrt <- gsub("t","",b.rooms$sqrt)
b.rooms <- b.rooms %>% 
<<<<<<< HEAD
  select(ID,rooms,sqrt)
=======
  select(ID,rooms,sqrt,housing_type)
>>>>>>> June

ft.only.index.b <- which(!1:nrow(b)%in%br.index.b)

b.sqrt <- b[ft.only.index.b,] %>% 
  mutate(sqrt=substr(housing_type,1,6)) 

b.sqrt$sqrt <- gsub("f","",b.sqrt$sqrt)
b.sqrt$sqrt <- gsub("t","",b.sqrt$sqrt)
b.sqrt <- b.sqrt %>% 
<<<<<<< HEAD
  select(ID,rooms,sqrt)
=======
  select(ID,rooms,sqrt,housing_type)
>>>>>>> June

#######
c <- result %>% 
  filter(as.numeric(row.names(result))%in%private_index)%>% 
  select(ID,housing_type,rooms,sqrt)
br.index.c <- grep("br",c$housing_type,value=FALSE)

c.messed <- c[br.index.c,]
c.unmessed <- c[-br.index.c,]

c.messed$rooms <- "private room"
c.messed$housing_type <- gsub("\\bprivate room\\b","",c.messed$housing_type)
c.messed$housing_type <- gsub("-","",c.messed$housing_type)
c.messed <- c.messed %>% 
  mutate(sqrt=substr(housing_type,6,9)) %>% 
  select(ID,rooms,sqrt)


c.unmessed$rooms <- "private room"
c.unmessed$housing_type <- gsub("\\bprivate room\\b","",c.unmessed$housing_type)

c.unmessed <- c.unmessed%>% 
  mutate(sqrt=substr(housing_type,1,6)) %>% 
  select(ID,rooms,sqrt)
c.unmessed$sqrt <- gsub("f","",c.unmessed$sqrt)
c.unmessed$sqrt <- gsub("t","",c.unmessed$sqrt)
#######

result <- result %>% 
  select(-rooms,-sqrt)

result <- merge(result,b.rooms,by="ID", all=TRUE)
result <- merge(result,b.sqrt,by="ID", all.x=TRUE)
result$rooms<-paste0(result$rooms.x,result$rooms.y)
result$sqrt<-paste0(result$sqrt.x,result$sqrt.y)
result$rooms <- gsub("NA","",result$rooms)
result$sqrt <- gsub("NA","",result$sqrt)
result <- result %>%
  select(-rooms.x,-rooms.y,-sqrt.x,-sqrt.y)


c. <- merge(c.unmessed,c.messed,by="ID", all =TRUE)
c.$rooms<-paste0(c.$rooms.x,c.$rooms.y) 
c.$sqrt<-paste0(c.$sqrt.x,c.$sqrt.y) 
c.$rooms <- gsub("NA","",c.$rooms)
c.$sqrt <- gsub("NA","",c.$sqrt)
c. <- c. %>% 
  select(-rooms.x,-rooms.y,-sqrt.x,-sqrt.y)

result <- merge(result,c.,by="ID", all.x=TRUE)
result$rooms<-paste0(result$rooms.x,result$rooms.y) 
result$sqrt<-paste0(result$sqrt.x,result$sqrt.y) 
result$rooms <- gsub("NA","",result$rooms)
result$sqrt <- gsub("NA","",result$sqrt)
result <- result %>% 
  select(-rooms.x,-rooms.y,-sqrt.x,-sqrt.y)

test <- result %>% 
  select(housing_type,rooms,sqrt)
