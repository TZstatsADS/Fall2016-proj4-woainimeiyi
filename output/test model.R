source("https://bioconductor.org/biocLite.R")
biocLite("rhdf5")
library(rhdf5)
###############
load("~/Desktop/ADS Project#4/Project4_data/lyr.RData")
data.lyr<-lyr[,-c(2,3,6:30)]
data.lyr.lda<-data.lyr[,-1]

files.test <- dir('~/Desktop/TestSongFile100', recursive = T, full.names = T, pattern = '\\.h5$')
sound.sum.test<-vector("list",length = length(files.test))
name.clean.test<-names(sound.sum.test[[1]])[c(8:13)]

for (i in 1:length(files.test)){
  sound.sum.test[[i]]<-h5read(file = files.test[i],"/analysis")
}
name.clean.test<-names(sound.sum.test[[1]])[c(8:13)]

for (i in 1:length(files.test)){
  sound.sum.clean.test[[i]]<-sound.sum.test[[i]][name.clean.test]
}

#################read 100 test songs
######pitch for 100 songs
feature.test<-vector("list",length = 100)
row.test<-vector(length = 500)
allsongs.test<-matrix(0,nrow = 100,ncol = 6000)
for (j in 1:100){
  for (i in 1:12) {
    row.test<-rep(sound.sum.clean.test[[j]]$segments_pitches[i,],length.out=500)
    feature.test[[j]]<-c(feature.test[[j]],row.reduce)}
  allsongs.test[j,]<-feature.test[[j]]
  #matrix.reduce[i,]<-row.reduce
}
######timbre for 100 songs
feature.test2<-vector("list",length = 100)
row.test2<-vector(length = 500)
allsongs.test2<-matrix(0,nrow = 100,ncol = 6000)
for (j in 1:100){
  for (i in 1:12) {
    row.test2<-rep(sound.sum.clean.test[[j]]$segments_timbre[i,],length.out=500)
    feature.test2[[j]]<-c(feature.test2[[j]],row.test2)}
  allsongs.test2[j,]<-feature.test2[[j]]
  #matrix.reduce[i,]<-row.reduce
}
all.testsongs<-cbind(allsongs.test,allsongs.test2)
####################100 songs with 2 features above

####################do topic model for 2350 training songs
topic.lda.test<-LDA(data.lyr.lda[1:2350,],k=10,method = "Gibbs", control = NULL,model = NULL)
####################We use the trained model to predict our test 100 songs
ridge.pred<-predict(ridge.fit.test,all.testsongs[1:100,],type = "response")

########
########we transfer the probility to ranks
test.word<-exp(topic.lda.test@beta)
ridge.mat<-ridge.pred[1:100,1:10,1]
ridge.ssr<-ridge.mat %*% test.word

zero.put<-matrix(0,nrow = 100,ncol = 1)
add1<-cbind(ridge.ssr[,1],zero.put,zero.put)
add2<-cbind(add1,ridge.ssr[,c(2,3)])
zero.put1<-matrix(0,nrow = 100,ncol = 25)
add3<-cbind(add2,zero.put1)
original.ssr<-cbind(add3,ridge.ssr[,c(4:4973)])


for (i in 1:100) {
  row.rank[i,]<-5001-rank(original.ssr[i,])
}
colnames(row.rank)<-colnames(lyr[,-1])
write.csv(row.rank,"~/Desktop/ADS P4 Table/100songs rank.csv")