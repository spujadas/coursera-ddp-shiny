library(plotly)

# LIST
# langsList
#
# DESCRIPTION
# List of languages with a corpus (read from a word frequency data file,
# named <lang>_50k.txt), mapping ISO 639-1 language codes to the English and
# native name of the languages

langsList <- list(
  "af" = "Afrikaans (Afrikaans)", 
  "br" = "Breton (brezhoneg)", 
  "bs" = "Bosnian (bosanski jezik)",
  "ca" = "Catalan (català)",
  "cs" = "Czech (čeština)",
  "da" = "Danish (dansk)",
  "de" = "German (Deutsch)",
  "en" = "English",
  "eo" = "Esperanto (Esperanto)",
  "es" = "Spanish (Español)",
  "et" = "Estonian (eesti)",
  "eu" = "Basque (euskara)",
  "fi" = "Finnish (suomi)",
  "fr" = "French (français)",
  "gl" = "Galician (galego)",
  "hr" = "Croatian (hrvatski jezik)",
  "hu" = "Hungarian (magyar)",
  "id" = "Indonesian (Bahasa Indonesia)",
  "is" = "Icelandic (Íslenska)",
  "it" = "Italian (Italiano)",
  "lt" = "Lithuanian (lietuvių kalba)",
  "lv" = "Latvian (latviešu valoda)",
  "ms" = "Malay (bahasa Melayu)",
  "nl" = "Dutch (Nederlands, Vlaams)",
  "no" = "Norwegian (Norsk)",
  "pl" = "Polish (język polski)",
  "pt" = "Portuguese (Português)",
  "ro" = "Romanian (Română)",
  "sk" = "Slovak (slovenčina)",
  "sl" = "Slovene (slovenski jezik)",
  "sq" = "Albanian (Shqip)",
  "sr" = "Serbian (srpski)",
  "sv" = "Swedish (svenska)",
  "tl" = "Tagalog (Wikang Tagalog)",
  "tr" = "Turkish (Türkçe)"
)


# FUNCTION
# readLanguageFrequencyData(freqDataFile)
# 
# DESCRIPTION
# Reads a word frequency data file and returns a word frequency data frame
#
# INPUT
# - freqDataFile: the name of a frequency data file, formatted as:
#   <word> <number of occurrences>
#   with one word per line (and angle brackets removed)
#
# OUTPUT
# A word frequency data frame, with the following columns:
# - index: the rank of the word, in decreasing order of frequency
# - word
# - occ: the number of occurrences of the word in the input text file
# - freq: the frequency of the word, expressed as a ratio of the number
#   of occurrences of the word to the total number of occurrences of all words

readLanguageFrequencyData <- function(freqDataFile) {
  freqData <- read.csv(freqDataFile, sep = " ", header = FALSE,
                       encoding = "UTF-8", stringsAsFactors = FALSE)
  freqData <- cbind(1:nrow(freqData), freqData)
  colnames(freqData) <- c("index", "word", "occ")
  totalOccurrences <- sum(freqData$occ)
  freqData$freq <- freqData$occ / totalOccurrences
  return(freqData)
}


# FUNCTION
# wordFrequencyFromText(txt)
# 
# DESCRIPTION
# Reads text and returns a word frequency data frame
#
# INPUT
# - txt: input text
#
# OUTPUT
# A word frequency data frame, with the following columns:
# - index: the rank of the word, in decreasing order of number of frequency
# - word
# - occ: the number of occurrences of the word in the input text file
# - freq: the frequency of the word, expressed as a ratio of the number
#   of occurrences of the word to the total number of occurrences of all words

wordFrequencyFromText <- function(txt) {
  # special case when input is the empty string
  if (txt == "") {
    return(NULL)
  }
  
  # count words
  freq <- txt %>%
    tolower() %>%
    strsplit("\\W") %>%
    unlist() %>%
    table() %>%
    sort(decreasing = TRUE)
  freq <- as.data.frame(freq, stringsAsFactors = FALSE)
  
  # special case when there is only one word
  if(nrow(freq) == 1) {
    # special case when the only word is empty
    if(rownames(freq) == "") {
      return(NULL)
    }
    
    return(data.frame(index = 1, word = rownames(freq), occ = 1, freq = 1))
  }
  
  # remove empty string
  freq <- freq[nzchar(freq[,1]),]
  
  # add index
  freq <- cbind(1:nrow(freq), freq)
  
  # add column names
  colnames(freq) <- c("index", "word", "occ")
  totalOccurrences <- sum(freq$occ)
  freq$freq <- freq$occ / totalOccurrences
  
  return(freq)
}


# LIST
# corpora
#
# DESCRIPTION
# List of corpora, mapping a language to a word frequency data frame

corpora <- sapply(names(langsList), function(lang) {
  readLanguageFrequencyData(
    freqDataFile = paste("corpora/", lang, "_50k.txt", sep = ""))
}, simplify = FALSE, USE.NAMES = TRUE)


# FUNCTION
# languageScore(corpus, wfText, nWordsInCorpus)
# 
# DESCRIPTION
# Calculates a language score of a text, assessing the likelihood that the
# text is written in a given language
#
# INPUT
# - corpus: the corpus of a language, from the corpora list
# - wfText: the word frequency data frame (as created by 
#   wordFrequencyFromText()) of the text to calculate the language score of
# - nWordsInCorpus: the number of words in the corpus to take into account to
#   calculate the language score
#
# OUTPUT
# The language score of the text for the language of the corpus

languageScore <- function(corpus, wfText, nWordsInCorpus) {
  wfText$isInCorpus <- wfText$word %in% 
    corpus$word[1:min(nWordsInCorpus, nrow(corpus))]
  wfText$freqIfInCorpus <- wfText$freq * wfText$isInCorpus
  sum(wfText$freqIfInCorpus)
}


# FUNCTION
# textScores(corpora, langs, txt, nWordsInCorpus)
# 
# DESCRIPTION
# Calculates the language scores of a text, assessing the likelihood that the
# text is written in a given language
#
# INPUT
# - corpora: a list of corpora
# - txt: input text
# - nWordsInCorpus: number of words in the corpora to take into account to
#   calculate the scores
#
# OUTPUT
# The language scores of the text

textScores <- function(corpora, txt, nWordsInCorpus) {
  freq <- wordFrequencyFromText(txt)
  if (is.null(freq)) {
    return(NULL)
  }
  
  scores <- sapply(names(corpora), 
                   function(corpora, lang, freq, nWordsInCorpus) {
    languageScore(corpora[[lang]], freq, nWordsInCorpus)
  }, USE.NAMES = TRUE, 
    corpora = corpora, 
    freq = wordFrequencyFromText(txt), 
    nWordsInCorpus = nWordsInCorpus)
  
  data.frame(language=names(scores), score=scores, row.names=NULL, 
             stringsAsFactors = FALSE)
}


# FUNCTION
# topLanguages(scores)
# 
# DESCRIPTION
# Returns the most likely language(s) that a text is written in
#
# INPUT
# - scores: the language scores of the text, as returned by textScores()
#
# OUTPUT
# The highest scoring language (or languages if several have the same score)

topLanguages <- function(scores) {
  # missing scores or all scores are 0 means that no language has been detected
  if (is.null(scores) || max(scores$score) == 0) {
    return(NULL)
  }
  
  # return languages with the highest score
  scores[scores$score == max(scores$score), "language"]
}


# FUNCTION
# languagesISO639_1toName(langsList, langsISO639_1)
# 
# DESCRIPTION
# Returns human-friendly name of languages based on their ISO 639-1 code
#
# INPUT
# - langsList: a list of languages mapping codes to native names
# - langsISO639_1: a vector of ISO 639-1 language codes (e.g. "en", "fr", "es")
#
# OUTPUT
# The English and native name of the language (e.g. "English",
# "French (français)", "Spanish (Español)")

languagesISO639_1toName <- function(langsList, langsISO639_1) {
  if (is.null(langsISO639_1)) {
    return(NULL)
  }
  paste(unlist(langsList[langsISO639_1], use.names = F), collapse = ", ")
}


# FUNCTION
# topNlanguages(langsList, scores, n)
# 
# DESCRIPTION
# Returns the most likely languages that a text is written in
#
# INPUT
# - langsList: a list of languages mapping codes to native names
# - scores: the language scores of the text, as returned by textScores()
# - n (optional): the number of languages to display (default: 10)
#
# OUTPUT
# The n highest scoring languages

topNlanguages <- function(langsList, scores, n = 10) {
  # missing scores or all scores are 0 means that no language has been detected
  if (is.null(scores) || max(scores$score) == 0) {
    return(NULL)
  }
  
  # return top n scoring languages
  sc <- scores[order(scores$score, decreasing = TRUE), ][1:min(n, nrow(scores)), ]
  sc$langName <- langsList[sc$language]
  sc
}


# FUNCTION
# wordFrequencyCorpusStats(wfText, corpus, nWordsInCorpus)
# 
# DESCRIPTION
# Adds statistics on word occurrence in the corpus to the list of words in the
# text
#
# INPUT
# - wfText: a word frequency data frame (as created by wordFrequencyFromText())
#   of the text
# - corpus: the corpus of a language, from the corpora list
# - nWordsInCorpus: number of words in the corpus to take into account
#
# OUTPUT
# A word frequency data frame, with the following additional columns:
# - freqInCorpus: frequency of the word in the corpus (0 if not in corpus)
# - rankInCorpus: the rank (by frequency) of the word in the corpus (NA if
#   not in corpus)

wordFrequencyCorpusStats <- function(wfText, corpus, nWordsInCorpus) {
  if (is.null(wfText)) {
    return(NULL)
  }
  
  # trim corpus to request number of words
  wfCorpus <- corpus[1:min(nWordsInCorpus, nrow(corpus)), ]
  
  # add column with frequency and rank in corpus of words from text
  wfText$freqInCorpus <- wfCorpus$freq[match(wfText$word, wfCorpus$word)]
  wfText$freqInCorpus[is.na(wfText$freqInCorpus)] <- 0
  wfText$rankInCorpus <- wfCorpus$index[match(wfText$word, wfCorpus$word)]
  
  wfText
}

# FUNCTION
# scorePlot(langsList, scores, n)
# 
# DESCRIPTION
# Creates a bar chart of the highest language scores
#
# INPUT
# - langsList: a list of languages mapping codes to human-friendly names
# - scores: the language scores of the text, as returned by textScores()
# - n (optional): the number of languages to display (default: 10)
#
# OUTPUT
# A bar chart of the n highest language scores

scorePlot <- function(langsList, scores, n = 10) {
  detectedLanguages <- topNlanguages(langsList, scores, n)
  if(is.null(detectedLanguages)) {
    return(NULL)
  }
  
  # plot
  plot_ly(detectedLanguages, x =~ language, y =~ score, type = "bar",
          hoverinfo = "text",
          text = ~paste('language: ', langName, "</br>score: ", round(score, 3)),
          source = "languages") %>%
    layout(xaxis = list(categoryarray = ~language, categoryorder = "array"),
           yaxis = list(range = c(0, 1)))
}


# FUNCTION
# freqPlot(wfText, corpus, nWordsInCorpus) {
# 
# DESCRIPTION
# Creates a scatter plot of the most frequent words in the text
#
# INPUT
# - wfText: a word frequency data frame (as created by wordFrequencyFromText())
#   of the text
# - corpus: the corpus of a language, from the corpora list
# - nWordsInCorpus: the number of words in the corpus taken into account to
#   calculate the language score
#
# OUTPUT
# A scatter plot of the most frequent words in the text, represented as the
# frequency in the corpus vs the frequency in the text

freqPlot <- function(wfText, corpus, nWordsInCorpus) {
  # add corpus stats to text word frequencies
  wfText <- wordFrequencyCorpusStats(wfText, 
                                     corpus,
                                     nWordsInCorpus)
  if(is.null(wfText)) {
    return(NULL)
  } 
  
  # plot
  plot_ly(wfText, x = ~freq, y = ~ freqInCorpus, hoverinfo = "text",
          text = ~paste(word, 
                        "</br>rank in text: ", index, 
                        "</br>frequency in text: ", freq,
                        "</br>rank in corpus: ", rankInCorpus,
                        "</br>frequency in corpus: ", freqInCorpus),
          name = "words",
          type = "scatter", mode = "markers") %>%
    add_lines(x = c(max(min(wfText$freq), 1e-6), max(wfText$freq)), 
              y = c(max(min(wfText$freq), 1e-6), max(wfText$freq)),
              name = "equal frequencies", color = I("#2DABFF"),
              text = "") %>%
                
    layout(
      xaxis = list(type = "log", 
                   title = "frequency in text"),
      yaxis = list(type = "log", 
                   title = "frequency in corpus")
    )
}


# FUNCTION
# rankPlot(wfText, corpus, nWordsInCorpus) {
# 
# DESCRIPTION
# Creates a plot of the most frequent words in the text and in the corpus
#
# INPUT
# - wfText: a word frequency data frame (as created by wordFrequencyFromText())
#   of the text
# - corpus: the corpus of the reference language language, from the corpora list
# - nWordsInCorpus: the number of words in the corpus taken into account to
#   calculate the language score
# - referenceLanguage: the name of the reference language (to be displayed
#   in the legend of the plot)
#
# OUTPUT
# A plot of the most frequent words in the text and the most frequent words
# in the corpus

rankPlot <- function(wfText, corpus, nWordsInCorpus, referenceLanguage) {
  if (is.null(wfText)) {
    return(NULL)
  }
  
  # trim text and corpus to nWordsInCorpora top ranking words
  wfText <- wfText[1:min(nWordsInCorpus, nrow(wfText)), ]
  wfCorpus <- corpus[1:min(nWordsInCorpus, nrow(corpus)), ]
  
  # fit linear regression
  fitText <- lm(log(freq) ~ log(index), data = wfText)
  fitCorpus <- lm(log(freq) ~ log(index), data = wfCorpus)
  
  # plot
  plot_ly(data = wfText, x = ~index, y = ~freq, hoverinfo = "text", 
          text = ~paste(word, 
                        "</br>rank: ", index, 
                        "</br>frequency: ", freq), 
          type = "scatter", mode = "markers", name = "text", 
          color = I("#1A7A90")) %>%
    add_lines(x = ~index, y = exp(fitted(fitText)), hoverinfo = "none",
              name = "text linear fit", color = I("#52A9BD"), opacity = I("0")) %>%
    add_markers(data = wfCorpus, x = ~index, y = ~freq, hoverinfo = "text", 
                text = ~paste(word, 
                              "</br>rank: ", index, 
                              "</br>frequency: ", freq),
                type = "scatter", 
                name = paste("corpus (", referenceLanguage, ")", sep = ""),
                color = I("#DC2340")) %>%
    add_lines(x = ~index, y = exp(fitted(fitCorpus)), hoverinfo = "none",
              name = "corpus linear fit", color = I("#F5677D"), opacity = I("0")) %>%
    layout(
      xaxis = list(
        type = "log", 
        title = "rank"),
      yaxis = list(
        type = "log", 
        title = "frequency")
    )
}