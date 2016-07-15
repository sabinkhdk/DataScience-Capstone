# This script to build n-grams from 20% of news and blogs data
# Removing twitter data for Now
library("tm")
library("ggplot2")
library("wordcloud")
library("NLP")
library("ngram")
library("dplyr")
library("stringr")

options(warn = -1)
##
dirpath <- "/Users/sabinkhadka/Github/DataScience-Capstone/"
setwd(dirpath)
###
fileurl <- "https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip"
if (!file.exists(file.path(dirpath,"Data.zip"))) {
        download.file(fileurl, dest="Data.zip", method="curl", 
                      quiet = FALSE, mode = "wb", cacheOK = TRUE) }
if (!file.exists(file.path(dirpath,"final"))){
        unzip("Data.zip", files = NULL, list = FALSE, overwrite = TRUE,
              junkpaths = FALSE, exdir = ".", unzip = "internal") }
###
blog <- paste0(dirpath, "final/en_US/",dir(paste0(dirpath,"/final/en_US"))[1])
blog_ <- readLines(blog)
news <- paste0(dirpath, "final/en_US/",dir(paste0(dirpath,"/final/en_US"))[2])
news_ <- readLines(news)
twit <- paste0(dirpath, "final/en_US/",dir(paste0(dirpath,"/final/en_US"))[3])
twit_ <- readLines(twit)
## Sample files
set.seed(12345)
sd_blog   <- c(1:length(blog_))
sd1_blog  <- sample(1:length(blog_), round(0.20*length(blog_)))
sd1_blog_ <- sd_blog[-sd1_blog]
sd2_blog  <- sample(sd1_blog_, round(0.20*length(blog_))) 
sd2_blog_ <- sd1_blog_[-sd2_blog]
sd3_blog  <- sample(sd2_blog_, round(0.20*length(blog_)))
blog_trn  <- blog_[sd1_blog] 
blog_val  <- blog_[sd2_blog]
blog_tst  <- blog_[sd3_blog]
set.seed(12346)
sd_news   <- c(1:length(news_))
sd1_news  <- sample(1:length(news_), round(0.20*length(news_)))
sd1_news_ <- sd_news[-sd1_news]
sd2_news  <- sample(sd1_news_, round(0.20*length(news_))) 
sd2_news_ <- sd1_news_[-sd2_news]
sd3_news  <- sample(sd2_news_, round(0.20*length(news_)))
news_trn  <- news_[sd1_news] 
news_val  <- news_[sd2_news]
news_tst  <- news_[sd3_news]
set.seed(12347)
sd_twit   <- c(1:length(twit_))
sd1_twit  <- sample(1:length(twit_), round(0.20*length(twit_)))
sd1_twit_ <- sd_twit[-sd1_twit]
sd2_twit  <- sample(sd1_twit_, round(0.20*length(twit_))) 
sd2_twit_ <- sd1_twit_[-sd2_twit]
sd3_twit  <- sample(sd2_twit_, round(0.20*length(twit_)))
twit_trn  <- twit_[sd1_twit] 
twit_val  <- twit_[sd2_twit]
twit_tst  <- twit_[sd3_twit]

dir.create(paste0(dirpath,"trn-data-20pcwithTweet"))
if (!file.exists(file.path(paste0(dirpath,"trn-data-20pcwithTweet/trn_blog20pc.txt")))) {
        writeLines(blog_trn, paste0(dirpath,"trn-data-20pcwithTweet/trn_blog20pc.txt"))
}
if (!file.exists(file.path(paste0(dirpath,"trn-data-20pcwithTweet/trn_news20pc.txt")))) {
        writeLines(news_trn, paste0(dirpath,"trn-data-20pcwithTweet/trn_news20pc.txt"))
}
if (!file.exists(file.path(paste0(dirpath,"trn-data-20pcwithTweet/trn_twit20pc.txt")))) {
        writeLines(twit_trn, paste0(dirpath,"trn-data-20pcwithTweet/trn_twit20pc.txt"))
}
dir.create(paste0(dirpath,"tst-data-20pcwithTweet"))
if (!file.exists(file.path(paste0(dirpath,"tst-data-20pcwithTweet/tst_blog20pc.txt")))) {
        writeLines(blog_tst, paste0(dirpath,"tst-data-20pcwithTweet/tst_blog20pc.txt"))
}
if (!file.exists(file.path(paste0(dirpath,"tst-data-20pcwithTweet/tst_news20pc.txt")))) {
        writeLines(news_tst, paste0(dirpath,"tst-data-20pcwithTweet/tst_news20pc.txt"))
}
if (!file.exists(file.path(paste0(dirpath,"tst-data-20pcwithTweet/tst_twit20pc.txt")))) {
        writeLines(twit_tst, paste0(dirpath,"tst-data-20pcwithTweet/tst_twit20pc.txt"))
}
dir.create(paste0(dirpath,"val-data-20pcwithTweet"))
if (!file.exists(file.path(paste0(dirpath,"val-data-20pcwithTweet/val_blog20pc.txt")))) {
        writeLines(blog_tst, paste0(dirpath,"val-data-20pcwithTweet/val_blog20pc.txt"))
}
if (!file.exists(file.path(paste0(dirpath,"val-data-20pcwithTweet/val_news20pc.txt")))) {
        writeLines(news_tst, paste0(dirpath,"val-data-20pcwithTweet/val_news20pc.txt"))
}
if (!file.exists(file.path(paste0(dirpath,"val-data-20pcwithTweet/val_twit20pc.txt")))) {
        writeLines(twit_tst, paste0(dirpath,"val-data-20pcwithTweet/val_twit20pc.txt"))
}
# Clear memory
rm(list = ls())
dirpath <- "/Users/sabinkhadka/Github/DataScience-Capstone/"
# Build Corpus for N-gram 
trn_corpus0 <- Corpus(DirSource(paste0(dirpath, "trn-data-20pcwithTweet")))
#trn_corpus0 <- trn_corpus
trn_corpus0 <- tm_map(trn_corpus0, stripWhitespace)
trn_corpus0 <- tm_map(trn_corpus0, removePunctuation)  
trn_corpus0 <- tm_map(trn_corpus0, removeNumbers)  
trn_corpus0 <- tm_map(trn_corpus0, removeWords, stopwords("english"))  
trn_corpus0 <- tm_map(trn_corpus0, content_transformer(tolower))
# Build N-gram
options(java.parameters = '-Xmx4g')
library("RWeka")
gc()

options(mc.cores=1)
Token_1 <- function(x) { NGramTokenizer(x, Weka_control(min = 1, max = 1)) }
Token_2 <- function(x) { NGramTokenizer(x, Weka_control(min = 2, max = 2)) }
Token_3 <- function(x) { NGramTokenizer(x, Weka_control(min = 3, max = 3)) }
Token_4 <- function(x) { NGramTokenizer(x, Weka_control(min = 4, max = 4)) }

unigram <- DocumentTermMatrix(trn_corpus0, control = list(tokenize = Token_1))
bigram  <- DocumentTermMatrix(trn_corpus0, control = list(tokenize = Token_2))
trigram <- DocumentTermMatrix(trn_corpus0, control = list(tokenize = Token_3))
quadgram <- DocumentTermMatrix(trn_corpus0, control = list(tokenize = Token_4))
save(trn_corpus0, unigram, bigram, trigram, quadgram, file = paste0(dirpath, "trn-data-20pcwithTweet/RawCorpNGramsFrom20pcwithTweet.RData"))

unigram_freq <- sort(colSums(as.matrix(unigram)), decreasing=TRUE)
bigram_freq  <- sort(colSums(as.matrix(bigram)), decreasing=TRUE)
trigram_freq <- sort(colSums(as.matrix(trigram)), decreasing=TRUE)
quadgram_freq <- sort(colSums(as.matrix(quadgram)), decreasing=TRUE)

unigramFreq <- data.frame(word=names(unigram_freq), freq=unigram_freq, stringsAsFactors = F)
bigramFreq <- data.frame(word=names(bigram_freq), freq=bigram_freq, stringsAsFactors = F)
trigramFreq <- data.frame(word=names(trigram_freq), freq=trigram_freq, stringsAsFactors = F)
quadgramFreq <- data.frame(word=names(quadgram_freq), freq=quadgram_freq, stringsAsFactors = F)
save(unigramFreq, bigramFreq, trigramFreq, quadgramFreq, file = paste0(dirpath, "trn-data-20pcwithTweet/allGramsFreq_dfs.RData"))
uni <- unigramFreq[unigramFreq$freq >1, ]
bi <- bigramFreq[bigramFreq$freq >1, ]
tri <- trigramFreq[trigramFreq$freq >1, ]
quad <- quadgramFreq[quadgramFreq$freq >1, ]
row.names(uni) <- NULL
row.names(bi) <- NULL
row.names(tri) <- NULL
row.names(quad) <- NULL
save(uni, bi, tri, quad, file = paste0(dirpath, "trn-data-20pcwithTweet/allGramsFreq_th1.RData"))
load(paste0(dirpath, "trn-data-20pcwithTweet/allGramsFreq_th2.RData"))


