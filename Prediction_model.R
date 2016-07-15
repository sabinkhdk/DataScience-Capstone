# Load libraries
library("tm")
library("ggplot2")
library("RWeka")
library("wordcloud")
library("SnowballC")

dirpath <- "/Users/sabinkhadka/Github/DataScience-Capstone/"
setwd(dirpath)
#download file from URL
fileurl <- "https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip"
if (!file.exists(file.path(dirpath,"Data.zip"))) {
        download.file(fileurl, dest="Data.zip", method="curl", 
                      quiet = FALSE, mode = "wb", cacheOK = TRUE)
}
if (!file.exists(file.path(dirpath,"final"))){
        unzip("Data.zip", files = NULL, list = FALSE, overwrite = TRUE,
              junkpaths = FALSE, exdir = ".", unzip = "internal")
}
## Read contents of the 
blog <- paste0(dirpath, "final/en_US/en_US.blogs.txt")
blog_ <- readLines(blog)
len_blog <- length(blog_)
news <- paste0(dirpath, "final/en_US/en_US.news.txt")
news_ <- readLines(news)
len_news <- length(news_)
twit <- paste0(dirpath, "final/en_US/en_US.twitter.txt")
twit_ <- readLines(twit)
merge_all <- c(blog_, news_, twit_, recursive=TRUE)
if (!file.exists(file.path(paste0(dirpath,"FileMerge/merge_all.txt")))) {
        dir.create(paste0(dirpath,"FileMerge"))
        writeLines(merge_all, paste0(dirpath,"FileMerge/merge_all.txt"))
} 
docs <- Corpus(DirSource(paste0(dirpath, "FileMerge")))
rm("blog", "blog_", "news", "news_", "twit", "twit_", "merge_all")
# Preprocess raw data
docs <- tm_map(docs, stripWhitespace)
docs <- tm_map(docs, removePunctuation)  
docs <- tm_map(docs, removeNumbers)  
docs <- tm_map(docs, removeWords, stopwords("english"))  
docs <- tm_map(docs, content_transformer(tolower)) 
save(docs, file="rawCorps.RData")
## http://www.cs.cmu.edu/~biglou/resources/bad-words.txt
bwords <- paste0(dirpath, "/bad-words.txt")
bwords_ <- readLines(bwords)
vbwords <- VectorSource(bwords_)
## remove words in bwords_
docs <- tm_map(docs, removeWords, bwords_)
save(docs, file="cleanCorps.RData")
cat(paste('proportion of most common call:',common.prop$Freq))
