if (!require(RecordLinkage)) install.packages("RecordLinkage")
library("RecordLinkage")

data(RLdata500)
RLdata500[1:5,]

pairs=compare.dedup(RLdata500,identity=identity.RLdata500,blockfld=list(c(1,3)),strcmpfun = jarowinkler,strcmp=TRUE)
summary(pairs)

#RLBigDataDedup(dataset, identity = NA, blockfld = list(), exclude = numeric(0),strcmp = numeric(0), strcmpfun = "jarowinkler", phonetic = numeric(0),phonfun = "pho_h")
pairs=emWeights(pairs)

hist(pairs$Wdata, plot=F)

getPairs(pairs,30,20)

pairs=emClassify(pairs, threshold.upper=24, threshold.lower=-7)

summary(pairs)

possibles <- getPairs(pairs, show="possible")

possibles[1:6,]
View(possibles)
links=getPairs(pairs,show="links", single.rows=TRUE)

link_ids <- links[, c("id1", "id2")]

link_ids

## Big data dedup

data(RLdata500)
data(RLdata10000)
# deduplication without blocking, use string comparator on names
rpairs <- RLBigDataDedup(RLdata500, identity = identity.RLdata500, strcmp=TRUE,blockfld = list(1,3),strcmpfun = 'jarowinkler' )

summary(rpairs)

rpairs=emWeights(rpairs)

hist(rpairs$Wdata, plot=F)

getPairs(rpairs,30,20)

pairs=emClassify(rpairs, threshold.upper=24, threshold.lower=-7)

summary(rpairs)

possibles <- getPairs(rpairs)
View(possibles)
possibles[1:6,]

links=getPairs(rpairs,show="links", single.rows=TRUE)

link_ids <- links[, c("id1", "id2")]

link_ids
# linkage with blocking on first name and year of birth, use phonetic
# code on first components of first and last name

# deduplication with blocking on either last name or complete date of birth,
# use string comparator on all fields, include identity information



# compare two strings:
jarowinkler("Andreas","Anreas")
# compare one string with several others:
levenshteinSim("Andreas",c("Anreas","Andeas"))
# compare two vectors of strings:
jarowinkler(c("Andreas","Borg"),c("Andreas","Bork"))



####

library(RecordLinkage)
# Jaro-Winkler cutoff
cutoff = 0.9
###################################################################### # Load and process the data 
###################################################################### 
data("RLdata10000")
dat = RLdata10000
dat$fi = substr(dat$fname_c1, 1, 1)
dat$li = substr(dat$lname_c1, 1, 1)
dedup = compare.dedup(dat, blockfld=c(8,9), exclude = c(2,4,8,9),
                      strcmp = c(1,3), identity=identity.RLdata10000)
pairs = dedup$pairs[,-c(1,2)]

pairs$fname_c1 = as.numeric(pairs$fname_c1>=cutoff) 
pairs$lname_c1 = as.numeric(pairs$lname_c1>=cutoff)
tdf = as.data.frame(table(pairs[,-ncol(pairs)]))
keep = rowSums(sapply(tdf[,-ncol(tdf)], as.numeric)-1)>=2
trunc_tdf = tdf 
trunc_tdf[!keep,ncol(tdf)] = 0
counts = trunc_tdf$Freq 
n = sum(counts)
###################################################################### # Build the design matrix ###################################################################### 
main.eff = matrix(as.numeric(as.matrix(tdf[,1:5])), nrow=nrow(tdf)) 
getind = function(s, n) {rr = rep(0, n); rr[s]=1; rr }
zero.indicator = sapply(which(counts==0), getind, n=nrow(trunc_tdf)) 
des = data.frame(main.eff, I=zero.indicator)
###################################################################### # Control settings for the EM algorithm ###################################################################### 
maxiter = 1000
tol = 1e-6 # Stopping criterion
###################################################################### # Begin EM algorithm ######################################################################
# Set initial values
# p_{M \mid beta, iota}
pM = 0.1
# pi_{g\mid U, beta , iota}
# Approximately the observed frequencies, since the
# total number of matches is small (add 2 to cell counts # to avoid issues from sampling zeros)
piU = (counts + 2)/sum(counts + 2)
piU = piU*as.numeric(keep)
piU = piU/sum(piU)
# pi_{g\mid M, beta , iota}
# Truncated conditional independence model with
# P(agree | match) = 0.95
piM = 0.95^rowSums(main.eff)*0.05^(5- rowSums(main.eff))
piM = piM*as.numeric(keep)
piM = piM/sum(piM)
for(i in 1:maxiter) {
  #Estep
  cprobM = (1-pM)*piU/((1-pM)*piU + pM*piM) nU = counts*cprobM
  nM = counts*(1-cprob0M)
  nU[!keep] = 0
  nM[!keep] = 0
  
  #Mstep
  glm.fit.0 = glm(y~., data=data.frame(y=nU, des), family="quasipoisson")
  glm.fit.1 = glm(y~., data=data.frame(y=nM, des), family="quasipoisson")
  pM = sum(nM)/n
  
  piU.old = piU 
  piM.old = piM
  
  g = function(fit, keep) {
  logwt = predict(fit)
  logwt = logwt - max(logwt)
  wt = as.numeric(keep)*exp(logwt) 
  wt/sum(wt)
  }
  piU = g(glm.fit.0, keep) 
  piM = g(glm.fit.1, keep)
  if (max(abs(log(piM/piU)[keep] - log(piM.old/piU.old)[keep])) < tol) break
  
  }
  