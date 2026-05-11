library(shiny)
library(tidyverse)
library(plotly)

source("make_pyramid.R")

function(input, output, session) {

  ticks <- reactive({
    if (is.null(input$file)) {
      process_ticks("ticks.csv")
    } else {
      process_ticks(input$file$datapath)
    }
  })

  output$year_filter <- renderUI({
    years <- sort(unique(ticks()$year), decreasing = TRUE)
    checkboxGroupInput(
      inputId  = "year",
      label    = "Year",
      choices  = years,
      selected = years
    )
  })

  filtered_ticks <- reactive({
    req(input$route_type, input$year)

    lead_styles <- switch(input$lead_style,
      all           = unique(ticks()$lead_style),
      sends         = c("Onsight", "Redpoint", "Pinkpoint", "Flash"),
      onsight_flash = c("Onsight", "Flash")
    )

    ticks() %>%
      filter(!is.na(rating_new), route_type %in% input$route_type,
             lead_style %in% lead_styles, year %in% as.integer(input$year))
  })

  output$pyramidPlot <- renderPlotly({
    ticks_summary <- filtered_ticks() %>%
      count(rating_new, lead_style, route_type) %>%
      group_by(rating_new, route_type) %>%
      mutate(
        total  = sum(n),
        xend   = cumsum(n) - total / 2,
        xstart = xend - n
      ) %>%
      ungroup()

    p <- ggplot(ticks_summary,
           aes(xmin = xstart, xmax = xend,
               ymin = as.numeric(rating_new) - 0.4,
               ymax = as.numeric(rating_new) + 0.4,
               fill = lead_style,
               text = paste0("Lead Style: ", lead_style, "<br>Count: ", n))) +
      geom_rect() +
      scale_y_continuous(breaks = seq_along(grade_levels), labels = grade_levels) +
      facet_wrap(~route_type) +
      labs(x = NULL, y = "Grade") +
      theme_minimal() +
      theme(strip.text      = element_text(size = 16, face = "bold"),
            legend.position = "none",
            axis.text.x     = element_blank(),
            axis.ticks.x    = element_blank())

    ggplotly(p, tooltip = "text")
  })

  output$pitch_count <- renderText({
    total <- sum(filtered_ticks()$pitches, na.rm = TRUE)
    paste("Total pitches climbed:", total)
  })

}
