library(shiny)
library(ggplot2)
library(sf)

map.data <- st_read("data/COVID19LSOAShiny.shp")

server <- function(input, output) {
  
  output$plot <- renderPlot({
    
    #Stop plot updating without clicking button
    input$run
    
    isolate({
      
      ggplot(subset(map.data, LAname==input$userLA), aes(fill=RGB, geometry=geometry))+
        geom_sf(colour=ifelse(input$LSOABoundaries==FALSE ,NA, "Gray30"))+
        theme_classic()+
        scale_fill_identity()+
        theme(axis.line=element_blank(), axis.ticks=element_blank(), axis.text=element_blank(),
              axis.title=element_blank(),  plot.title=element_text(face="bold"))+
        labs(title=paste("Mapping potential COVID-19 risk across", input$userLA),
             subtitle="LSOA-level health deprivation and potential COVID-19 mortality risk based on age-sex structure of population",
             caption="Population data from ONS, CFRs from Istituto Superiore di Sanità\nPlot by @VictimOfMaths")
    })
  })
}