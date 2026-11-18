library(shiny)
library(plotly)

fluidPage(
  titlePanel("Climbing Pyramid"),
  h4(textOutput("climber_name")),

  wellPanel(
    h4("Load a climber's ticks"),
    tags$ol(
      tags$li("On mountainproject.com, open the climber's profile page ",
              "(click their name anywhere on the site, or open your own profile)."),
      tags$li("Copy the web address from your browser's address bar. It looks like ",
              tags$code("https://www.mountainproject.com/user/123456789/your-name"), "."),
      tags$li("Paste it below and click ", tags$b("Load ticks"), ". ",
              "Just the number (", tags$code("123456789"), ") works too.")
    ),
    helpText("The climber's ticks must be public on Mountain Project. ",
             "You can also upload a CSV exported from the Ticks page of their profile."),
    fluidRow(
      column(6, textInput("mp_user", label = NULL, width = "100%",
                          placeholder = "https://www.mountainproject.com/user/123456789/your-name")),
      column(2, actionButton("load_user", "Load ticks", class = "btn-primary")),
      column(4, fileInput("file", label = NULL, accept = ".csv",
                          buttonLabel = "Upload CSV", placeholder = "or upload a CSV"))
    ),
    uiOutput("load_status")
  ),

  tabsetPanel(

    tabPanel("Pyramid",
      sidebarLayout(
        sidebarPanel(
          checkboxGroupInput(
            inputId  = "route_type",
            label    = "Route Type",
            choices  = c("Sport", "Trad", "Toprope", "Aid", "Ice", "Boulder"),
            selected = c("Sport", "Trad")
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
          h4(textOutput("pitch_count")),
          helpText(
            "Note on grades: for 5.10 and harder, \"-\" grades are counted as \"a\"",
            "and \"+\" grades as \"d\" (e.g. 5.11- becomes 5.11a, 5.11+ becomes 5.11d).",
            "Below 5.10, +/- is dropped (e.g. 5.9+ becomes 5.9).",
            "A grade with no letter counts as \"a\" (5.12 becomes 5.12a).",
            "Aid routes use their free-climbing grade when they have one; C grades are counted as the matching A grade.",
            "+/- is also dropped on boulder (V1+ becomes V1) and ice (WI5- becomes WI5) grades."
          )
        )
      )
    ),

    tabPanel("Map",
      sidebarLayout(
        sidebarPanel(
          checkboxGroupInput(
            inputId  = "map_route_type",
            label    = "Route Type",
            choices  = c("Sport", "Trad", "Toprope", "Aid", "Ice", "Boulder"),
            selected = c("Sport", "Trad")
          ),
          helpText("States are shaded by number of ticks. Climbs outside the US are not shown.")
        ),
        mainPanel(
          plotlyOutput("mapPlot", height = "600px")
        )
      )
    ),

    tabPanel("Progress",
      plotlyOutput("longitudinalPlot", height = "600px")
    )

  )
)
