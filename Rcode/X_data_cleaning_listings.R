if (!require(stringdist)) install.packages("stringdist")
if (!require(PASWR)) install.packages("PASWR")
if (!require(DescTools)) install.packages("DescTools")
library(DescTools)
library (MASS)
library(dplyr)
library(stringdist)
library(PASWR)



# x <- c("I have a pen")
# y <- c("I have an appen")
# StrDist(x, y, method = "normlevenshtein")


#Load data set
s<-getwd()
substr(s, 1, nchar(s)-5)
datapath<-paste(substr(s, 1, nchar(s)-5),"results/Standardized_Deduped_Datasets/June_Clean_20180719.csv",sep = "")
#If you cannot load the raw dataset, you need to set it by yourself by matching the csv file name.
result <- read.csv(file=datapath,header=T,stringsAsFactors = FALSE)

#Arrangnig the dataset by title.
result<- result %>% 
  arrange(description)

#Adding index cuz the rowname is not functioning very well.
result$ID <- seq.int(nrow(result))

result <- result %>% 
  mutate(gcs=paste(lat,long))

#There is no missing values for titles, nor description
#But there are some empty title and description, so I am deleting empty titles.
result <- result[!(result$title==""),]

#CSV file of empty title entry for Jocelyn. 
# empty.title <- result[(result$title==""),]
# write.csv(empty.title, file = "emptytitle.csv", append = FALSE, quote = TRUE, sep = " ",
#             eol = "\n", na = "NA", dec = ".", row.names = TRUE,
#             col.names = TRUE, qmethod = c("escape", "double"),
#             fileEncoding = "")

#Let's delete the exact duplicates from the same name "or" the same description
dif.ttl.or.dif.des<- result %>% 
  filter(!duplicated(title)|!duplicated(description)) %>% 
  arrange(lat,long)

dif.ttl.and.dif.des<- result %>% 
  filter(!duplicated(title)&!duplicated(description)) %>% 
  arrange(lat,long)


#same title
same.title <- result %>% 
  filter(duplicated(title))

#same desc
same.desc <- result %>% 
  filter(duplicated(description))

#same title and different description
same.ttl.diff.desc <- same.title %>% 
  filter(!(ID%in%same.desc$ID))

#Let A subset that has different title,
#Let B subset that has different description,
#Let c subset that has different location.

#Let's make subset B-A-C:same location with same title, different description
#and name it as temp:same title, dif desc, same location

temp <- same.ttl.diff.desc %>% 
  filter(duplicated(gcs))


temp <- temp[!is.na(temp$lat),]
temp <- temp[!is.na(temp$long),]

#B-(A∪C): temp



#Excluding B-(A∪C)
#same location with same title, different description is excluded.
excl.same.ttl.same.loc.dif.des <- dif.ttl.or.dif.des %>% 
  filter(!(ID%in%temp$ID)) %>% 
  arrange(lat,long)


same.desc.diff.ttl <- same.desc %>% 
  filter(!(ID%in%same.title$ID)) %>% 
  arrange(description) 



#So many ,,,, description makes it confused, so will delete them.
desc.temp <- gsub(","," ",same.desc.diff.ttl$description)
desc.temp <- gsub("\n"," ",same.desc.diff.ttl$description)
same.desc.diff.ttl<- same.desc.diff.ttl[grep("\\b \\b", desc.temp),] %>% arrange(lat)

#Let's remove this part.
same.desc.diff.ttl.same.loc <- same.desc.diff.ttl %>% filter(duplicated(gcs))

#it's removing data with two variables having same values.
excl.same.desc.same.loc.dif.ttl <-  excl.same.ttl.same.loc.dif.des%>% 
  filter(!(ID%in%same.desc.diff.ttl.same.loc$ID))

#So we have excl.same.desc.same.loc.dif.ttl data frame!

#So anyway,if [i,j]value exceeds 400, I will remove it. 
#If i>j, [i,j]and [j,i] will have the same value. I will delete the second one, which means i.
dup.candidates <- c()
for (i in 1:(nrow(edit.matrix)-1)) {
  for (j in (i+1):nrow(edit.matrix)) {
    if (edit.matrix[i,j]<200) {
      dup.candidates <- c(dup.candidates,j)
    }
  }
}

dup.candidates <- dup.candidates[!duplicated(dup.candidates)]



#########For duplicates only
set.seed(1)
##let's sample 100 observations from the A union B.
sampled.index <- sample(1:nrow(dif.ttl.or.dif.des), 100, replace = FALSE)
##
sampled.data <- dif.ttl.or.dif.des %>% 
  filter(as.numeric(rownames(dif.ttl.or.dif.des))%in%sampled.index) %>% 
  arrange(title)

#ID first, removing "" next result goes to the dataset, and we got the matrix.
dif.ttl.or.dif.des <- rownames_to_column(dif.ttl.or.dif.des,var="rowname")
sample.edit.matrix <- matrix(data=NA, nrow=100, ncol=100)
rownames(sample.edit.matrix) <- sampled.data$ID
colnames(sample.edit.matrix) <- sampled.data$ID
for (i in 1:(nrow(sampled.data)-1)) {
  for (j in (i+1):nrow(sampled.data)) {
    first.id <- sampled.data$ID[i]
    second.id <- sampled.data$ID[j]
    matrix.index <- dif.ttl.or.dif.des %>% filter(ID%in%c(first.id,second.id)) %>% dplyr::select(rowname) %>% arrange(rowname)
    matrix.index <- as.numeric(matrix.index$rowname)
    edit.value <- edit.matrix[matrix.index[1],matrix.index[2]]
    sample.edit.matrix[i,j] <- edit.value
    }
  }
sample.edit.vector <- as.vector(sample.edit.matrix)
his.nondup <- hist(sample.edit.vector)
###########

#########So I am comparing the difference of the distributions of two subset.
set.seed(1)
sampled.index <- sample(1:nrow(same.ttl.diff.desc), 100, replace = FALSE)

sampled.data <- same.ttl.diff.desc %>% 
  filter(as.numeric(rownames(same.ttl.diff.desc))%in%sampled.index) %>% 
  arrange(title)

#ID first, removing "" next result goes to the dataset, and we got the matrix.
dif.ttl.or.dif.des <- rownames_to_column(dif.ttl.or.dif.des,var="rowname")
sample.edit.matrix <- matrix(data=NA, nrow=100, ncol=100)
rownames(sample.edit.matrix) <- sampled.data$ID
colnames(sample.edit.matrix) <- sampled.data$ID
for (i in 1:(nrow(sampled.data)-1)) {
  for (j in (i+1):nrow(sampled.data)) {
    first.id <- sampled.data$ID[i]
    second.id <- sampled.data$ID[j]
    matrix.index <- dif.ttl.or.dif.des %>% filter(ID%in%c(first.id,second.id)) %>% dplyr::select(rowname) %>% arrange(rowname)
    matrix.index <- as.numeric(matrix.index$rowname)
    edit.value <- edit.matrix[matrix.index[1],matrix.index[2]]
    sample.edit.matrix[i,j] <- edit.value
  }
}
sample.edit.vector.dup <- as.vector(sample.edit.matrix)
his.du <- hist(sample.edit.vector.dup)
hist(sample.edit.vector.dup)
hist(sample.edit.vector)
View(his.nondup)
###########

a <- as.vector(edit.matrix)
hist(a)



