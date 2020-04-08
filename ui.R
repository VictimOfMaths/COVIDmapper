library(shiny)
library(ggplot2)
library(sf)

ui <- fluidPage(
  
  #Set up title
  titlePanel("COVID-19 potential risk mapper"),
  
  #Set up sidebar for user inputs
  sidebarLayout(
    
    sidebarPanel("User inputs",
                 textInput("userLA" , "Select LA to map" , "Sheffield"),
                 #textInput("userLAname", "Select LA name for map title", "Sheffield"),
                 checkboxInput("LSOABoundaries", "Show LSOA boundaries", value=TRUE),
                 radioButtons("legendpos", "Select legend position", choices=list("Top left"=1,
                                                                                  "Top right"=2,
                                                                                  "Bottom left"=3,
                                                                                  "Bottom right"=4,
                                                                                  "No legend"=5),
                              selected=3),
                 actionButton("run", "Generate plot"),
                 width=2),
    
    #Set up main panel for the plot
    mainPanel(
      plotOutput("plot"))
  )
)
