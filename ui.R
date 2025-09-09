#**************************
#   Trigger Word Finder   #
#       Fulcrum           #
#      08/21/2025         #
#**************************

# Libraries
library(dplyr) # data management
library(DT) # html tables
library(officer) # read ms word docs
library(openxlsx2) # export Excel data
library(shiny) # runs the show
library(shinydashboard) # runs the show
library(stringr) # data management
library(tools) # validation

# Define UI for application that draws a histogram
dashboardPage(
  # Application title
  dashboardHeader(
    title="Trigger Word Finder",
    titleWidth=275
  ),
  dashboardSidebar(disable=TRUE),
  dashboardBody(
    fluidRow(
      box(
        width=12,
        status="primary", solidHeader=TRUE, title="Welcome",
        p("Sorry you're here."),
        p("If you need to check a grant or other document against the massive list 
          of trigger words and don't want to burn down a rainforest using/training 
          an AI, you're in the right place."),
        p("This dashboard will allow you to upload a Microsoft Word document and 
          check it against the list of trigger words shown below, or you may 
          upload your own list of words. (File size limit is 10 MB each.) If your 
          document contains any of the words in the trigger list, they will appear 
          in the table to the right."),
        p('Partial matches are flagged to be on the safe side. For example, if 
          your document contains the word "abortions," the trigger word 
          "abortion" will get flagged. Shorter triggers (i.e. "ej") will probably 
          flag a lot of words that are not actually triggers, so fine-tune your 
          search in the Word document as appropriate.')
      )
    ),
    fluidRow(
      box(
        width=6,
        status="info", solidHeader=TRUE, title="Step 1: Trigger List",
        p("An initial list of trigger words and suggested replacements is provided 
        here. (Note that some replacements may also be triggers!) You may use the 
          search function below to check and ensure that the words you need 
          flagged are included. If you would like to modify this list, download 
          as either a .csv or .xlsx file, modify as you see fit, and re-upload."),
        DTOutput("triggerTbl"),
        p("Don’t see what you need? Download the above list and modify, or create 
          your own from scratch. Upload a new .csv or .xlsx file. The uploaded file 
          must have only two columns: ",
          code("Trigger")," and ", code("Replacement"),"."),
        downloadButton(
          outputId="trigExDl",
          label=HTML("Download<br/>Excel")
        ),
        downloadButton(
          outputId="trigCsDl",
          label=HTML("Download<br/>csv")
        ),
        br(),
        br(),
        fileInput(inputId="trigUpload",
                  label="Upload new trigger file:",
                  accept=c(".csv",".xlsx")),
        actionButton(
          inputId="trigRestore",
          label=HTML("Goof up?<br/>Restore original list")
        )
      ),
      box(
        width=6,
        status="danger", solidHeader=TRUE, title="Step 2: Document Check",
        p("Once you've set up your trigger list, upload the MS Word document you 
          need to check. Flagged words and suggested replacements will appear below. 
          You may download this list as either a .csv or .xlsx file so that you 
          can search and correct your document offline."),
        fileInput(inputId="docUpload",
                  label="Upload your MSWord document here:",
                  accept=".docx"),
        DTOutput("flaggedTbl"),
        br(),
        downloadButton(
          outputId="flagExDl",
          label=HTML("Download<br/>Excel")
        ),
        downloadButton(
          outputId="flagCsDl",
          label=HTML("Download<br/>csv")
        )
      )
    ),
    fluidRow(
      wellPanel(
        textOutput("upDate")
      )
    )
    
    
    
    
     
  )
)
