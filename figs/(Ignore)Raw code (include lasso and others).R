source("https://bioconductor.org/biocLite.R")
biocLite("rhdf5")
library(rhdf5)
data.lyr<-lyr[,-c(2,3,6:30)]
data.lyr.lda<-data.lyr[,-1]
song.test<-h5ls("~/Desktop/ADS Project#4/Project4_data/data/A/A/A/TRAAABD128F429CF47.h5")
sound<-h5read("~/Desktop/ADS Project#4/Project4_data/data/A/A/A/TRAAABD128F429CF47.h5", "/analysis")
sound$segments_loudness_max
sound2<-h5read("~/Desktop/ADS Project#4/Project4_data/data/A/A/A/TRAAAFD128F92F423A.h5", "/analysis")

files <- dir('~/Desktop/ADS Project#4/Project4_data/data', recursive = T, full.names = T, pattern = '\\.h5$')
sound.sum<-vector("list",length = length(files))
for (i in 1:length(files)){
  sound.sum[[i]]<-h5read(file = files[i],"/analysis")
}
####这个是去掉了songs之后的features
name.clean<-names(sound.sum[[1]])[c(8:13)]

for (i in 1:length(files)){
  sound.sum.clean[[i]]<-sound.sum[[i]][name.clean]
}
######Use LDA to divide lyr into different topics
library(topicmodels)
?`TopicModel-class`
topic.lda<-LDA(data.lyr.lda,k=10,method = "Gibbs", control = NULL,model = NULL)
######Find the length of feature
length.feature<-vector()
for (i in 1:length(files)) {
  length.feature[i]<-length(sound.sum.clean[[i]]$segments_loudness_max)
}
quantile(length.feature,probs = c(0.95))

############把矩阵的每行剪短，构成一个vector，长度为6000
#matrix.reduce<-matrix(0,ncol = 500,nrow = 12)
feature.reduce<-vector("list",length = 2350)
row.reduce<-vector(length = 500)
allsongs.feature<-matrix(0,nrow = 2350,ncol = 6000)
for (j in 1:2350){
  for (i in 1:12) {
    row.reduce<-rep(sound.sum.clean[[j]]$segments_pitches[i,],length.out=500)
    feature.reduce[[j]]<-c(feature.reduce[[j]],row.reduce)}
    allsongs.feature[j,]<-feature.reduce[[j]]
    #matrix.reduce[i,]<-row.reduce
}
#######这是对另一个feature做cut，长度为6000，再构成matrix
feature.reduce.2<-vector("list",length = 2350)
row.reduce.2<-vector(length = 500)
allsongs.feature.2<-matrix(0,nrow = 2350,ncol = 6000)
for (j in 1:2350){
  for (i in 1:12) {
    row.reduce.2<-rep(sound.sum.clean[[j]]$segments_timbre[i,],length.out=500)
    feature.reduce.2[[j]]<-c(feature.reduce.2[[j]],row.reduce.2)}
    allsongs.feature.2[j,]<-feature.reduce.2[[j]]
  #matrix.reduce[i,]<-row.reduce
}

allsongs.feature.total<-cbind(allsongs.feature,allsongs.feature.2)
####use ridge to fit the x and y
library(glmnet)
library(MASS)
ridge.fit<-cv.glmnet(allsongs.feature,topic.lda@gamma,family=c("mgaussian"),alpha=0,nfold=5)
ridge.fit.test<-glmnet(allsongs.feature,topic.lda@gamma,family=c("mgaussian"),lambda = ridge.fit$lambda.min,alpha = 0)
####use the ridge model to predict
abc123<-predict(ridge.fit.test,as.matrix(allsongs.feature[c(111,521),]),type="response")
exp.b<-exp(topic.lda@beta)

lol<-abc123[1:2,1:10,1] %*% exp.b
rank(lol[1,])

#####test distance
dis.mat<-vector()
for (i in 1:2350){
  dis.mat[i]<-dist(rbind(allsongs.feature[i,],allsongs.feature[1,]))
}
####################
####################用2250做train，剩下的100做test
feature.reduce.test<-vector("list",length = 2250)
row.reduce.test<-vector(length = 500)
allsongs.feature.test<-matrix(0,nrow = 2250,ncol = 6000)
for (j in 1:2250){
  for (i in 1:12) {
    row.reduce.test<-rep(sound.sum.clean[[j]]$segments_pitches[i,],length.out=500)
    feature.reduce.test[[j]]<-c(feature.reduce.test[[j]],row.reduce.test)}
    allsongs.feature.test[j,]<-feature.reduce.test[[j]]
  #matrix.reduce[i,]<-row.reduce
}
#######这是对另一个feature做cut，长度为6000，再构成matrix
feature.reduce.test.2<-vector("list",length = 2250)
row.reduce.test.2<-vector(length = 500)
allsongs.feature.test.2<-matrix(0,nrow = 2250,ncol = 6000)
for (j in 1:2250){
  for (i in 1:12) {
    row.reduce.test.2<-rep(sound.sum.clean[[j]]$segments_timbre[i,],length.out=500)
    feature.reduce.test.2[[j]]<-c(feature.reduce.test.2[[j]],row.reduce.test.2)}
  allsongs.feature.test.2[j,]<-feature.reduce.test.2[[j]]
  #matrix.reduce[i,]<-row.reduce
}
#######2个feature合并之后的
allsongs.feature.train<-cbind(allsongs.feature.test,allsongs.feature.test.2)

topic.lda.test<-LDA(data.lyr.lda[1:2250,],k=10,method = "Gibbs", control = NULL,model = NULL)

system.time(ridge.fit<-cv.glmnet(allsongs.feature.train,topic.lda.test@gamma,family=c("mgaussian"),alpha=0,nfold=5))
ridge.fit.test<-glmnet(allsongs.feature.train,topic.lda.test@gamma,family=c("mgaussian"),lambda = ridge.fit$lambda.min,alpha = 0)

ridge.pred<-predict(ridge.fit.test,allsongs.feature.total[2251:2350,],type = "response")
test.word<-exp(topic.lda.test@beta)
ridge.mat<-ridge.pred[1:100,1:10,1]
ridge.ssr<-ridge.mat %*% test.word
ridge.n<-vector(length = 100)

for (i in 1:100) {
  ridge.n[i]<-mean((5001-rank(ridge.ssr[i,])[which(data.lyr.lda[i,]!=0)]))/mean(5001-rank(ridge.ssr[i,]))
}

mean(ridge.n)
rank(ridge.pred[1,1:10,1])
#####correct rank
index.2350<-vector()
rank.2350<-vector()
result<-vector(length = 100)
for (i in 2251:2350) {
  index.2350<-which(data.lyr.lda[i,]!=0)
  rank.2350<-rank(data.lyr.lda[i,])[index.2350]
  result[i-2250]<-mean(5001-rank.2350)
}

index.2350<-which(data.lyr.lda[2350,]!=0)
rank.2350<-rank(data.lyr.lda[2350,])[index.2350]
mean(5001-rank.2350[index.2350])
mean(5001-rank.2350)
#####lasso
system.time(lasso.fit<-cv.glmnet(allsongs.feature.train,topic.lda.test@gamma,family=c("mgaussian"),alpha=1,nfold=5))
lasso.fit.test<-glmnet(allsongs.feature.train,topic.lda.test@gamma,family=c("mgaussian"),lambda = lasso.fit$lambda.min,alpha = 1)
lasso.pred<-predict(lasso.fit.test,allsongs.feature.total[2251:2350,],type = "response")

lasso.mat<-lasso.pred[1:100,1:10,1]
lasso.ssr<-lasso.mat %*% test.word
lasso.n<-vector(length = 100)


for (i in 1:100) {
  lasso.n[i]<-mean((5001-rank(lasso.ssr[i,])[which(data.lyr.lda[i,]!=0)]))/mean(5001-rank(lasso.ssr[i,]))
}

mean(lasso.n)