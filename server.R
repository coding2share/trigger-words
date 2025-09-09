#**************************
#   Trigger Word Finder   #
#       Fulcrum           #
#      08/21/2025         #
#**************************

# date updated
upDt <- "2025.08.21"

# Load starting trigger list
triggerWb <- wb_load(file="TriggersReplacements.xlsx")

# bump upload file size limits to 10 MB (default is 5)
options(shiny.maxRequestSize = 10 * 1024^2)

# Functions ####

# display html table
tblFun <- function(df, domCom){
  scrY <- if (nrow(df) > 12) {500} else {NULL} # vertical scroll if > 12 rows
  datatable(df%>%
              select(Trigger, Replacement), rownames=FALSE,
            options=list(dom=domCom, paging=FALSE, scrollY=scrY))
}

# Shiny Server ####
function(input, output, session) {
  
  # trigger list ####
  # initialize original list
  triggerDf <- reactiveVal(
    triggerWb %>%
      wb_to_df(sheet="Sheet1") %>%
      mutate(Trigger = tolower(Trigger),
             matchRow = row_number())
  ) 
  # display original list
  output$triggerTbl <- renderDT({
    tblFun(triggerDf(), domCom="tf")
  })
  # download original excel file
  output$trigExDl <- downloadHandler(
    filename="TriggerWordList.xlsx",
    content=function(file){
      wb_save(triggerWb, file)
    }
  )
  # download original as csv
  output$trigCsDl <- downloadHandler(
    filename="TriggerWordList.csv",
    content=function(file){
      write.csv(triggerDf() %>%
                  select(!matchRow),
                row.names=FALSE, na="", file)
    }
  )
  # upload new trigger list & update in display
  observeEvent(input$trigUpload,{
    trigExt <- file_ext(input$trigUpload$name)
    # run verification
    if(!trigExt %in% c("csv","xlsx")){
      showModal(
        modalDialog(
          title="Error",
          "Invalid file; Please upload a .csv or .xlsx file.")
        )
    } else if(trigExt == "csv") {
      temp <- read.csv(input$trigUpload$datapath)
    } else if(trigExt == "xlsx") {
      temp <- read_xlsx(file=input$trigUpload$datapath)
    }
    if (exists("temp")) {
      cNames <- paste0(names(temp), collapse=", ")
      if (identical(names(temp),c("Trigger","Replacement"))){
        triggerDf(
          temp %>%
            mutate(Trigger = tolower(Trigger)) %>%
            # handle any duplicate triggers and combine suggested replacements
            group_by(Trigger) %>%
            summarize(Replacement = str_c(Replacement, collapse="; ")) %>%
            mutate(matchRow = row_number())
                   
        )
      } else {
        showModal(
          modalDialog(
            title="Error",
            paste0("Invalid file: Submitted column names are ",cNames,
            ". Columns must only be 'Trigger' and 'Replacement'.")
          )
        )
      }
    } 
  })
  # restore original list
  observeEvent(input$trigRestore,{
    triggerDf(triggerWb %>%
                wb_to_df(sheet="Sheet1") %>%
                mutate(Trigger = tolower(Trigger),
                       matchRow = row_number()))
  })
  
  # document upload ####
  
  # initialize upload extension and docObj
  ext <- reactiveVal()
  docObj <- reactiveVal()
  
  # upload
  observeEvent(input$docUpload,{
    ext(file_ext(input$docUpload$name))
    if(ext() != "docx"){
      showModal(modalDialog(
        title="Error",
        "Invalid file; Please upload a .docx file.")
        )
      docObj(NULL) # wipes out render of pre-existing stuff with req below
    } else {
      docObj(read_docx(input$docUpload$datapath))
    }
  })
  
  # run search & display ####
  
  # extract text from docObj and collapse to single string
  wordStr <- reactive({
    req(!is.null(docObj()))
    docObj() %>%
      docx_summary() %>%
      pull(text) %>%
      paste(collapse=" ") %>% # collapse headings, paragraphs, etc
      tolower() # all lowercase
  })

  # run the search, convert flagged words to data frame, match up with replacements
  flaggedDf <- reactive({
    lapply(triggerDf()$Trigger, grepl, wordStr(), fixed=TRUE) %>%
      unlist() %>%
      matrix(nrow=nrow(triggerDf()), byrow=TRUE) %>%
      data.frame() %>%
      mutate(matchRow = row_number()) %>%
      rename(testVal=".") %>%
      filter(testVal==TRUE) %>%
      left_join(triggerDf(), by="matchRow") %>%
      select(Trigger, Replacement) %>%
      arrange(Trigger)
  })
  
  # display table
  output$flaggedTbl <- renderDT({
    req(!is.null(docObj()))
    validate(need(nrow(flaggedDf()) > 0, "No flagged words found - all set!"))
    tblFun(flaggedDf(), domCom="t")
  })
  
  # download results ####
  
  # excel
  output$flagExDl <- downloadHandler(
    filename="FlaggedWordList.xlsx",
    content=function(file){
      dl <- local({
        wb <- wb_workbook() %>%
          wb_add_worksheet("Flagged") %>%
          wb_add_data(x=flaggedDf(), na.strings="") %>%
          wb_set_col_widths(cols=1:ncol(flaggedDf()), widths="auto") %>%
          wb_freeze_pane(first_row=TRUE)
        return(wb)
      })
      wb_save(dl, file)
    }
  )
  
  # csv
  output$flagCsDl <- downloadHandler(
    filename="FlaggedWordList.csv",
    content=function(file){
      write.csv(flaggedDf(),
                row.names=FALSE, na="", file)
    }
  )

  # date updated
  output$upDate <- renderText(paste0("Last updated: ",upDt))
}
