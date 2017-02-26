library(shiny)

# load constants and functions used by server
source("language-detection.R", encoding = "UTF-8")

# server logic
shinyServer(function(input, output) {
  scores <- reactive({
    textScores(corpora, enc2native(input$txt), input$nWordsInCorpora)
  })
  
  wordFrequency <- reactive({
    wordFrequencyFromText(enc2native(input$txt))
  })
  
  output$language <- renderText({
    langs <- languagesISO639_1toName(langsList, topLanguages(scores()))
    if (is.null(langs)) {
      "---"
    }
    else {
      langs
    }
  })
   
  output$scorePlot <- renderPlotly({
    p <- scorePlot(langsList, scores())
    if (is.null(p)) { return(NULL) }
    p
  })

  output$freqPlot <- renderPlotly({
    # get language from bar that was clicked on in score plot
    event.data <- event_data("plotly_click", source = "languages")
    referenceLanguage <- event.data[[3]]
    if(is.null(referenceLanguage)) { return(NULL) }
    
    # create and display plot
    p <- freqPlot(wordFrequency(), 
                  corpora[[referenceLanguage]],
                  input$nWordsInCorpora)
    if (is.null(p)) { return(NULL) }
    p
  })
  
  output$rankPlot <- renderPlotly({
    # get language from bar that was clicked on in score plot
    event.data <- event_data("plotly_click", source = "languages")
    referenceLanguage <- event.data[[3]]
    if(is.null(referenceLanguage)) { return(NULL) }
    
    # create and display plot
    p <- rankPlot(wordFrequency(), 
                  corpora[[referenceLanguage]], 
                  input$nWordsInCorpora,
                  referenceLanguage)
    if (is.null(p)) { return(NULL) }
    p
  })
  
  
})
