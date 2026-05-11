library(shiny)
library(plotly)

fluidPage(
  titlePanel("Climbing Pyramid"),
  textOutput("climber_name"),

  tabsetPanel(

    tabPanel("Pyramid",
      sidebarLayout(
        sidebarPanel(
          fileInput(
            inputId  = "file",
            label    = "Upload Mountain Project CSV",
            accept   = ".csv"
          ),

          checkboxGroupInput(
            inputId  = "route_type",
            label    = "Route Type",
            choices  = c("Sport", "Trad", "Toprope"),
            selected = c("Sport", "Trad", "Toprope")
          ),

          uiOutput("year_filter"),

          radioButtons(
            inputId  = "lead_style",
            label    = "Style",
            choices  = c(
              "All"                                    = "all",
              "Onsight / Redpoint / Pinkpoint / Flash" = "sends",
              "Onsight / Flash only"                   = "onsight_flash"
            ),
            selected = "all"
          )
        ),

        mainPanel(
          plotlyOutput("pyramidPlot", height = "600px"),
          h4(textOutput("pitch_count"))
        )
      )
    ),

    tabPanel("Progress",
      plotlyOutput("longitudinalPlot", height = "600px")
    )

  )
)
