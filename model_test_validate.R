library("tm")
library("ggplot2")
library("wordcloud")
library("NLP")
library("ngram")
library("dplyr")
library("stringr")
library("shiny")

options(warn = -1)
rm(list=ls())
dirpath <- "/Users/sabinkhadka/Github/DataScience-Capstone/"
setwd(dirpath)
#load(paste0(dirpath, "trn-data-20pcNoTweet/allGramsFrom20pcNoTweet_th2.RData"))
#load(paste0(dirpath, "trn-data-20pcNoTweet/allGramsFrom20pcNoTweet_th1.RData"))
#load(paste0(dirpath, "trn-data-25pcNoTweet/allGramsFreq_th1.RData"))
load(paste0(dirpath, "trn-data-20pcwithTweet/allGramsFreq_th2.RData"))
predictfromTri <- function(input, lambda=0.01, u=uni, b=bi, t=tri) {
        input <- tolower(input)
        input <- gsub('[[:digit:]]+', '', input)
        input <- gsub('[[:punct:]]+', '', input)
        input <- gsub('!@#$%^&*()_+:\"<>?,./;','', input)
        input <- gsub("^\\s+|\\s+$", "", input)
        ip_split <- unlist(str_split(input, " "))
        biWord <- tail(ip_split, 2)
        triStart <- paste0('^', paste(biWord[1], biWord[2]))
        triExact <- paste0(triStart,'$')
        biStart <- paste0('^', biWord[2])
        biExact <- paste0(biStart,'$')
        SliceTRI <- NULL
        SliceTRI <- tri[grep(triStart, tri$word),]  # Slice trigram with Starting with
        tmp0 <- as.data.frame(str_split_fixed(SliceTRI$word, ' ', 3), stringsAsFactors = F)
        SliceTRI$outword <- tmp0$V3
        SliceTRI$biStart <- paste(tmp0$V1, tmp0$V2)
        SliceTRI <- SliceTRI[grep(triExact, SliceTRI$biStart),]
        SliceTRI$Score <- SliceTRI$freq / sum(SliceTRI$freq)
        tmp_df0 <- as.data.frame(SliceTRI[,c('outword', 'Score')])
        row.names(tmp_df0) <- NULL
        SliceBI <- bi[grep(biStart, bi$word),]
        tmp1 <- as.data.frame(str_split_fixed(SliceBI$word, ' ', 2), stringsAsFactors = F)
        SliceBI$outword <- tmp1$V2
        SliceBI$uniStart <- tmp1$V1
        SliceBI <- SliceBI[grep(biExact, SliceBI$uniStart),]
        SliceBI <- filter(SliceBI, !(SliceBI$outword %in% SliceTRI$outword))
        SliceBI$Score <- lambda*SliceBI$freq / sum(SliceBI$freq)
        tmp_df1 <- as.data.frame(SliceBI[, c('outword', 'Score')])
        row.names(tmp_df1) <- NULL
        SliceUI <- filter(uni, !(uni$word %in% tmp_df0$outword))
        SliceUI <- filter(SliceUI, !(SliceUI$word %in% tmp_df1$outword))
        SliceUI$Score <- lambda*lambda*SliceUI$freq / nrow(SliceUI)
        tmp_df2 <- as.data.frame(SliceUI[,c('word', 'Score')])
        colnames(tmp_df2) <- colnames(tmp_df1)
        row.names(tmp_df2) <- NULL
        tmp_dfs <- rbind(tmp_df0, tmp_df1, tmp_df2)
        tmp_dfs <- tmp_dfs[order(-tmp_dfs$Score),]
        tmp_dfs <- tmp_dfs[order(-tmp_dfs$Score),]
        return(as.data.frame(head(tmp_dfs, 5)))
}
predictfromBi <- function(input, lambda=0.01, u=uni, b=bi) {
        input <- tolower(input)
        input <- gsub('[[:digit:]]+', '', input)
        input <- gsub('[[:punct:]]+', '', input)
        input <- gsub('!@#$%^&*()_+:\"<>?,./;','', input)
        input <- gsub("^\\s+|\\s+$", "", input)
        ip_split <- unlist(str_split(input, " "))
        biWord <- tail(ip_split, 1)
        biStart <- paste0('^', biWord[1])
        biExact <- paste0(biStart,'$')
        SliceBI <- bi[grep(biStart, bi$word),]
        tmp1 <- as.data.frame(str_split_fixed(SliceBI$word, ' ', 2), stringsAsFactors = F)
        SliceBI$outword <- tmp1$V2
        SliceBI$uniStart <- tmp1$V1
        SliceBI <- SliceBI[grep(biExact, SliceBI$uniStart),]
        #SliceBI <- filter(SliceBI, !(SliceBI$outword %in% SliceBI$outword))
        SliceBI$Score <- SliceBI$freq / sum(SliceBI$freq)
        tmp_df1 <- as.data.frame(SliceBI[, c('outword', 'Score')])
        row.names(tmp_df1) <- NULL
        SliceUI <- filter(uni, !(uni$word %in% tmp_df1$outword))
        SliceUI <- filter(SliceUI, !(SliceUI$word %in% tmp_df1$outword))
        SliceUI$Score <- lambda*SliceUI$freq / nrow(SliceUI)
        tmp_df2 <- as.data.frame(SliceUI[,c('word', 'Score')])
        colnames(tmp_df2) <- colnames(tmp_df1)
        row.names(tmp_df2) <- NULL
        tmp_dfs <- rbind(tmp_df1, tmp_df2)
        tmp_dfs <- tmp_dfs[order(-tmp_dfs$Score),]
        return(as.data.frame(head(tmp_dfs, 5)))
}
LetsPredict <- function(input, lambda=0.01) {
        if (length(unlist(str_split(input, " "))) == 1) {
                predictfromBi(input)
        } else {
                predictfromTri(input) } 
}

### Now test the model
#rd1 <- readLines(paste0(dirpath,'tst-data-20pcwithTweet/tst_blog20pc.txt'))
#rd2 <- readLines(paste0(dirpath,'tst-data-20pcwithTweet/tst_news20pc.txt'))
#rd3 <- readLines(paste0(dirpath,'tst-data-20pcwithTweet/tst_twit20pc.txt'))
#rdd<- sample(rdall, 1000, replace = F)
#save(rdd,file='tstrdd.Rdata')
load('rdd.Rdata')
## for validation
#rd1 <- readLines(paste0(dirpath,'val-data-20pcwithTweet/val_blog20pc.txt'))
#rd2 <- readLines(paste0(dirpath,'val-data-20pcwithTweet/val_news20pc.txt'))
#rd3 <- readLines(paste0(dirpath,'val-data-20pcwithTweet/val_twit20pc.txt'))
#rdall <- c(rd1 ,rd2, rd3)
#save(rdall, file = 'val_rdall.Rdata')
#load('val_rdall.Rdata')
#rdd <- rdall[c(1:150)]
#rdd<- sample(rdall, 1000, replace = F)
#save(rdd,file='valrdd.Rdata')
#load('valrdd.Rdata')
sm <- 0
for (i in seq(1:length(rdd))){cat(i)
        inp <- tolower(rdd[i])
        inp <- gsub('[[:digit:]]+', '', inp)
        inp <- gsub('[[:punct:]]+', '', inp)
        inp <- gsub('!@#$%^&*()_+:\"<>?,./;','', inp)
        inp <- gsub("^\\s+|\\s+$", "", inp)
        ip_sp <- unlist(str_split(inp, " ")) 
        b <- paste(tail(ip_sp,3)[1], tail(ip_sp,2)[1])
        l <- tail(ip_sp, 1)
        op <- LetsPredict(input = b, lambda=0.01)
        if (l %in% op$outword) {sm <- sm+1}
        cat(paste('\n')) }

acc = sm*100/1000
cat(paste('accuracy : ', acc))


