source("https://bioconductor.org/biocLite.R")
biocLite("rhdf5")
library(rhdf5)
#################
load("~/Desktop/ADS Project#4/Project4_data/lyr.RData")
data.lyr<-lyr[,-c(2,3,6:30)]
data.lyr.lda<-data.lyr[,-1]
files <- dir('~/Desktop/ADS Project#4/Project4_data/data', recursive = T, full.names = T, pattern = '\\.h5$')
sound.sum<-vector("list",length = length(files))
for (i in 1:length(files)){
  sound.sum[[i]]<-h5read(file = files[i],"/analysis")
}
name.clean<-names(sound.sum[[1]])[c(8:13)]
sound.sum.clean.test<-vector("list")
for (i in 1:length(files.test)){
  sound.sum.clean.test[[i]]<-sound.sum.test[[i]][name.clean]
}

library(topicmodels)
topic.lda<-LDA(data.lyr.lda,k=10,method = "Gibbs", control = NULL,model = NULL)

######all songs 2350 for pitch
feature.reduce.test<-vector("list",length = 2350)
row.reduce.test<-vector(length = 500)
allsongs.feature.test<-matrix(0,nrow = 2350,ncol = 6000)
for (j in 1:2350){
  for (i in 1:12) {
    row.reduce.test<-rep(sound.sum.clean[[j]]$segments_pitches[i,],length.out=500)
    feature.reduce.test[[j]]<-c(feature.reduce.test[[j]],row.reduce.test)}
  allsongs.feature.test[j,]<-feature.reduce.test[[j]]
}
#######2350 songs for timbre
feature.reduce.test.2<-vector("list",length = 2350)
row.reduce.test.2<-vector(length = 500)
allsongs.feature.test.2<-matrix(0,nrow = 2350,ncol = 6000)
for (j in 1:2350){
  for (i in 1:12) {
    row.reduce.test.2<-rep(sound.sum.clean[[j]]$segments_timbre[i,],length.out=500)
    feature.reduce.test.2[[j]]<-c(feature.reduce.test.2[[j]],row.reduce.test.2)}
  allsongs.feature.test.2[j,]<-feature.reduce.test.2[[j]]
}

allsongs.feature.train<-cbind(allsongs.feature.test,allsongs.feature.test.2)

topic.lda.test<-LDA(data.lyr.lda[1:2350,],k=10,method = "Gibbs", control = NULL,model = NULL)

system.time(ridge.fit<-cv.glmnet(allsongs.feature.train,topic.lda.test@gamma,family=c("mgaussian"),alpha=0,nfold=5))
ridge.fit.test<-glmnet(allsongs.feature.train,topic.lda.test@gamma,family=c("mgaussian"),lambda = ridge.fit$lambda.min,alpha = 0)
########################
########################
########################
#######After this, they are just for me to test the model.
ridge.pred<-predict(ridge.fit.test,all.testsongs[2001:2350,],type = "response")
ridge.n<-vector(length = 350)
for (i in 1:350) {
  ridge.n[i]<-mean((5001-rank(ridge.ssr[i,])[which(data.lyr.lda[i,]!=0)]))/mean(5001-rank(ridge.ssr[i,]))
}

mean(ridge.n)
rank(ridge.pred[1,1:10,1])
#####correct rank(ignore)
index.2350<-vector()
rank.2350<-vector()
result<-vector(length = 100)
for (i in 2001:2350) {
  index.2350<-which(data.lyr.lda[i,]!=0)
  rank.2350<-rank(data.lyr.lda[i,])[index.2350]
  result[i-2000]<-mean(5001-rank.2350)
}

#####lasso
system.time(lasso.fit<-cv.glmnet(allsongs.feature.train,topic.lda.test@gamma,family=c("mgaussian"),alpha=1,nfold=5))
lasso.fit.test<-glmnet(allsongs.feature.train,topic.lda.test@gamma,family=c("mgaussian"),lambda = lasso.fit$lambda.min,alpha = 1)
lasso.pred<-predict(lasso.fit.test,allsongs.feature.total[2001:2350,],type = "response")

lasso.mat<-lasso.pred[1:350,1:10,1]
lasso.ssr<-lasso.mat %*% test.word
lasso.n<-vector(length = 350)


for (i in 1:350) {
  lasso.n[i]<-mean((5001-rank(lasso.ssr[i,])[which(data.lyr.lda[i,]!=0)]))/mean(5001-rank(lasso.ssr[i,]))
}
mean(lasso.n)