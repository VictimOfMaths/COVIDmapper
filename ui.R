ui <- fluidPage(
  
  #Set up title
  titlePanel("COVID-19 potential risk mapper"),
  
  #Set up sidebar for user inputs
  sidebarLayout(
    
    sidebarPanel("User inputs",
                 textInput("userLA" , "Select LA or LAs to map. Separate multiple LAs with :" , "Sheffield"),
                 textInput("userLAname", "Select area name for map title", "Sheffield"),
                 p("For a list of LA names click ",
                   a("here", href="https://github.com/VictimOfMaths/COVIDmapper/blob/master/LAlist.csv")),
                 #br(),
                 checkboxInput("LSOABoundaries", "Show LSOA boundaries", value=TRUE),
                 #br(),
                 radioButtons("legendpos", "Select legend position", choices=list("Top left"=1,
                                                                                  "Top right"=2,
                                                                                  "Bottom left"=3,
                                                                                  "Bottom right"=4,
                                                                                  "No legend"=5),
                              selected=3),
                 actionButton("run", "Generate plot"),
                 width=3),
    
    #Set up main panel for the plot
    mainPanel(
      fluidRow(plotOutput("plot")),
      br(),
      fluidRow(downloadButton('covid_download'))
    ) # end mainpanel
  ),
  hr(),
  p("Health deprivation taken from the health component of the Index of Multiple Deprivation. Age-sex risk based on age-specific Infection Fatality Rates from ", 
        a("Imperial College modelling,", 
        href="https://www.imperial.ac.uk/media/imperial-college/medicine/sph/ide/gida-fellowships/Imperial-College-COVID19-NPI-modelling-16-03-2020.pdf"), 
    "adapted to estimated age-sex-specific rates using male:female outcome ratios from Italy from ",
    a("Istituto Superiore di Sanità.", href="https://www.epicentro.iss.it/coronavirus/bollettino/Bollettino-sorveglianza-integrata-COVID-19_26-marzo%202020.pdf"),
  "This analysis assumes 100% infection rates and therefore represents the maximum potential mortality exposure of each area. Approach adapted from and inspired by the work of ",
    a("Ilya Kashnitsky and José Aburto", href="https://doi.org/10.31219/osf.io/abx7s"))
)
