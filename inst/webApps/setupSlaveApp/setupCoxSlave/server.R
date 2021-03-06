shinyServer(function(input, output, session) {

  ## -- Begin: functions to make tabs active sequentially --
  ## First time make sure Data Upload is selected
  session$sendCustomMessage('activeNavs', 'Data Upload')
  updateTabsetPanel(session, inputId="navigationList", selected="Data Upload")
  observe({
    if (input$uploadData > 0 && is.data.frame(getComputationInfo("data"))) {
      session$sendCustomMessage('activeNavs', 'Sanity Check')
      updateTabsetPanel(session, inputId="navigationList", selected="Sanity Check")
    }
  })
  observe({
    if (input$checkSanity > 0 && !is.null(getComputationInfo("formula"))) {
      ##session$sendCustomMessage('activeNavs', 'Output Result')
      updateTabsetPanel(session, inputId="navigationList", selected="Output Result")
    }
  })
  observe({
    if (input$exitApp > 0) stopApp(TRUE)
  })

  ## -- End: functions to make tabs active sequentially --

  ## Variables to detect various states the app can be in, depending
  ## on what actions the user has taken.

  ## output$datasetSpecified
  ## output$datasetChecked
  ## output$formulaEntered
  ## output$formulaChecked
  ## output$definitionSaved

  ## When the user chooses a file and clicks on the "Upload Data" button
  ## this function is triggered
  output$dataFileContentSummary <- renderPrint({
    if (input$uploadData == 0) return("")
    ## Create data frame from file
    isolate({
      inputFile <- input$dataFile
      shiny::validate(
        need(inputFile != "", "Please select a data set")
      )

      ## Parse missing value strings
      missingValueIndicators <- stringr::str_trim(scan(textConnection(input$missingIndicators),
                                                       what = character(0), sep=",", quiet=TRUE))
      ## Return data frame or error as the case may be
      dataResult <- tryCatch(
        { read.csv(file = inputFile$datapath, na.strings = missingValueIndicators) } ,
        warning = function(x) x,
        error = function(x) x
      )

      if (is.data.frame(dataResult)){
        setComputationInfo("data", dataResult) ## Store data object
        updateTabsetPanel(session, inputId="navigationList", selected="Sanity Check")
        str(dataResult)
      } else {
        cat('Error!', dataResult$message)
      }
    })
  })

  output$dataUploaded <- reactive({
    if (input$uploadData == 0) return()
    ifelse(is.data.frame(getComputationInfo("data")), "Data Uploaded; Proceed to Sanity Check", "")
  })

  ## When the user clicks on the "Check Sanity" button
  ## this function is triggered
  output$sanityCheckResult <- reactive({
    if (input$checkSanity == 0) return()
    formula <- getComputationInfo("formula")
    isolate({
      result <- tryCatch(
        { coxSlave$new(formula = as.formula(formula), data=getComputationInfo("data")) },
        warning = function(x) x,
        error = function(x) x)
      if ("CoxSlave" %in% class(result)) { ## Success
        "Success: data matches formula. Proceed to output."
      } else {
        paste("Error!", result$message)
      }
    })
  })

  output$populateResult <- renderPrint({
    if (input$populateServer == 0) return()
    isolate({
      shiny::validate(need(input$siteName != "", "Please enter a site name"))
      shiny::validate(need(input$ocpuURL != "", "Please enter an opencpu URL"))
      url <- input$ocpuURL
      localhost <- (grepl("^http://localhost", url) || grepl("^http://127.0.0.1", url))
      defn <- makeDefinition(getComputationInfo("compType"))
      data <- getComputationInfo("data")
      dataFileName <- paste0(input$siteName, ".rds")
      result <- tryCatch(ifelse(localhost,
                                uploadNewComputation(url=url, defn=defn, data=data, dataFileName=dataFileName),
                                uploadNewComputation(url=url, defn=defn, data=data)),
                         error = function(x) x,
                         warning = function(x) x)
      if (inherits(result, "error") ) {
        "Error: Uploading the definition to server"
      } else {
        ifelse(result, "Success: definition uploaded to server",
               "Error while uploading definition to server")
      }
    })
  })

})

