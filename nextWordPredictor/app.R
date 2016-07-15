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
#dirpath <- "/Users/sabinkhadka/Github/DataScience-Capstone/"
#setwd(dirpath)
#load(paste0(dirpath, "trn-data-20pcwithTweet/allGramsFreq_th2.RData"))
load('allGramsFreq_th2.RData')
predictfromTri <- function(input, u=uni, b=bi, t=tri) {
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
        SliceBI$Score <- 0.01*SliceBI$freq / sum(SliceBI$freq)
        tmp_df1 <- as.data.frame(SliceBI[, c('outword', 'Score')])
        row.names(tmp_df1) <- NULL
        SliceUI <- filter(uni, !(uni$word %in% tmp_df0$outword))
        SliceUI <- filter(SliceUI, !(SliceUI$word %in% tmp_df1$outword))
        SliceUI$Score <- 001*0.01*SliceUI$freq / nrow(SliceUI)
        tmp_df2 <- as.data.frame(SliceUI[,c('word', 'Score')])
        colnames(tmp_df2) <- colnames(tmp_df1)
        row.names(tmp_df2) <- NULL
        tmp_dfs <- rbind(tmp_df0, tmp_df1, tmp_df2)
        tmp_dfs <- tmp_dfs[order(-tmp_dfs$Score),]
        tmp_dfs <- tmp_dfs[order(-tmp_dfs$Score),]
        return(as.data.frame(head(tmp_dfs, 5)))
}
predictfromBi <- function(input, u=uni, b=bi) {
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
        SliceUI$Score <- 0.01*SliceUI$freq / nrow(SliceUI)
        tmp_df2 <- as.data.frame(SliceUI[,c('word', 'Score')])
        colnames(tmp_df2) <- colnames(tmp_df1)
        row.names(tmp_df2) <- NULL
        tmp_dfs <- rbind(tmp_df1, tmp_df2)
        tmp_dfs <- tmp_dfs[order(-tmp_dfs$Score),]
        return(as.data.frame(head(tmp_dfs, 5)))
}
LetsPredict <- function(input) {
        if (length(unlist(str_split(input, " "))) == 1) {
                predictfromBi(input)
        } else {
                predictfromTri(input) } 
}

ui <- fluidPage(
        headerPanel("What's Next? Keep typing..."),
        sidebarPanel(
                textInput('word', 'Type Here'),
                submitButton('Submit')
        ),
        mainPanel(
                tabsetPanel(type="tabs",
                            tabPanel("Results",
                                     h4('Next Word'),
                                     textOutput('Next'),
                                     h4('Five top next probable words:'),
                                     tableOutput('outWords')),
                            tabPanel("Help", position = 'right',
                                     h3('Your Word Prediction App'),
                                     h4('This word prediction app was built as Capstone Project for Data Science Specialization'),
                                     h3('Input'),
                                     h4('The unigrams, bigrams, trigrams were built using blogs.txt, twit.txt and news.txt files.'),
                                     h4('Only 20% of the documents were used due to memory constraint'),
                                     h4('For word prediction model we used "Stupid Back-off Model" backing off from trigram'),
                                     h3('Stupid Backoff Algorithm:'),
                                     h5('Step 1: Start with trigram'),
                                     h5('Step 2: If not in trigram backoff to bigram multiplying probability with some lambda value'),
                                     h5('Step 3: If not in bigram backoff to unigram multiplying probability with lambda^2 value'),
                                     h3('Output'),
                                     h4('Predict word with high Score')))
                
        )
)

server <- function(input, output) {
        output$inputWords <- renderPrint({input$word})
        output$outWords <- renderTable({LetsPredict(input$word)})
        output$Next <- renderPrint({LetsPredict(input$word)[1,1]})
}

shinyApp(ui = ui, server = server)