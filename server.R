library(shiny)
library(tidyverse)
library(plotly)

source("make_pyramid.R")

function(input, output, session) {

  default_url  <- "https://www.mountainproject.com/user/112174408/julia-wrobel/tick-export"
  default_name <- "Julia Wrobel"

  # Whatever was loaded most recently (profile link or CSV upload) wins.
  data_source <- reactiveVal(list(url = default_url, name = default_name))
  load_status <- reactiveVal(NULL)

  observeEvent(input$load_user, {
    req(nzchar(str_trim(input$mp_user)))
    result <- tryCatch({
      user <- resolve_mp_user(input$mp_user)
      process_ticks(user$url)   # check the export loads before switching
      user
    }, error = function(e) e)

    if (inherits(result, "error")) {
      load_status(div(class = "text-danger", conditionMessage(result)))
    } else {
      data_source(result)
      load_status(div(class = "text-success", "Loaded ticks for ", result$name, "."))
    }
  })

  observeEvent(input$file, {
    data_source(list(path = input$file$datapath, name = NULL))
    load_status(div(class = "text-success", "Loaded ", input$file$name, "."))
  })

  output$load_status <- renderUI(load_status())

  ticks <- reactive({
    src <- data_source()
    if (!is.null(src$path)) {
      process_ticks(src$path)
    } else if (identical(src$url, default_url)) {
      tryCatch(process_ticks(src$url), error = function(e) process_ticks("ticks.csv"))
    } else {
      process_ticks(src$url)
    }
  })

  output$climber_name <- renderText({
    name <- data_source()$name
    if (is.null(name)) "" else paste("Climber:", name)
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
      sends         = c("Onsight", "Redpoint", "Pinkpoint", "Flash", "Send"),
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
        xstart = xend - n,
        key    = paste(route_type, rating_new, lead_style, sep = "|")
      ) %>%
      ungroup()

    # Rope-climbing facets (graded on the YDS scale) share one grade range so
    # they can be compared; boulder and ice facets get their own range.
    yds_rows  <- ticks_summary %>% filter(rating_new %in% yds_levels)
    yds_blank <- if (nrow(yds_rows) > 0) {
      expand_grid(route_type = unique(yds_rows$route_type),
                  y = range(as.numeric(yds_rows$rating_new)))
    } else {
      tibble(route_type = character(), y = numeric())
    }

    p <- ggplot(ticks_summary,
           aes(xmin = xstart, xmax = xend,
               ymin = as.numeric(rating_new) - 0.4,
               ymax = as.numeric(rating_new) + 0.4,
               fill = lead_style, key = key,
               text = paste0("Lead Style: ", lead_style, "<br>Count: ", n,
                             "<br><i>Click to see routes</i>"))) +
      geom_rect() +
      geom_blank(data = yds_blank, aes(y = y), inherit.aes = FALSE) +
      scale_fill_manual(values = lead_style_colors, name = NULL) +
      scale_y_continuous(breaks = seq_along(grade_levels), labels = grade_levels) +
      facet_wrap(~route_type, scales = "free_y") +
      labs(x = NULL, y = "Grade") +
      theme_minimal() +
      theme(strip.text      = element_text(size = 16, face = "bold"),
axis.text.x     = element_blank(),
            axis.ticks.x    = element_blank())

    # Send the clicked chunk's key to Shiny as an event, so clicking the same
    # chunk twice still reopens the route list.
    split_rect_traces(ggplotly(p, tooltip = "text"), ticks_summary) %>%
      htmlwidgets::onRender("
        function(el) {
          el.on('plotly_click', function(d) {
            var key = [].concat(d.points[0].data.key).find(Boolean);
            if (key) Shiny.setInputValue('pyramid_click', key, {priority: 'event'});
          });
        }")
  })

  # Clicking a chunk of the pyramid opens a list of the routes in it.
  observeEvent(input$pyramid_click, {
    key <- input$pyramid_click
    parts <- strsplit(key, "|", fixed = TRUE)[[1]]

    routes <- filtered_ticks() %>%
      filter(route_type == parts[1], rating_new == parts[2], lead_style == parts[3]) %>%
      arrange(desc(date))

    rows <- pmap(list(routes$route, routes$url, routes$rating, routes$date,
                      routes$location, routes$pitches),
      function(route, url, rating, date, location, pitches) {
        tags$tr(
          tags$td(tags$a(route, href = url, target = "_blank")),
          tags$td(rating),
          tags$td(format(date, "%b %d, %Y"), style = "white-space: nowrap"),
          tags$td(pitches),
          tags$td(str_replace_all(location, " > ", " › "))
        )
      })

    showModal(modalDialog(
      title     = paste0(parts[2], " ", parts[1], " · ", parts[3],
                         " (", nrow(routes), if (nrow(routes) == 1) " tick)" else " ticks)"),
      size      = "l",
      easyClose = TRUE,
      footer    = modalButton("Close"),
      tags$table(class = "table table-condensed table-striped",
        tags$thead(tags$tr(tags$th("Route"), tags$th("Grade"), tags$th("Date"),
                           tags$th("Pitches"), tags$th("Location"))),
        tags$tbody(rows))
    ))
  })

  output$pitch_count <- renderText({
    total <- sum(filtered_ticks()$pitches, na.rm = TRUE)
    paste("Total pitches climbed:", total)
  })

  output$mapPlot <- renderPlotly({
    req(input$map_route_type)

    us_ticks <- ticks() %>%
      filter(route_type %in% input$map_route_type, state %in% state.name)

    top_areas <- us_ticks %>%
      count(state, area, sort = TRUE) %>%
      group_by(state) %>%
      slice_head(n = 5) %>%
      summarise(areas = paste0(area, " (", n, ")", collapse = "<br>"))

    state_summary <- us_ticks %>%
      group_by(state) %>%
      summarise(ticks = n(), pitches = sum(pitches, na.rm = TRUE)) %>%
      left_join(top_areas, by = "state") %>%
      mutate(
        abb   = state.abb[match(state, state.name)],
        hover = paste0("<b>", state, "</b><br>Ticks: ", ticks,
                       "<br>Pitches: ", pitches, "<br><br>Top areas:<br>", areas)
      )

    plot_geo(state_summary, locationmode = "USA-states") %>%
      add_trace(
        type = "choropleth", z = ~ticks, locations = ~abb,
        text = ~hover, hoverinfo = "text",
        colorscale = "YlOrRd", reversescale = FALSE,
        marker = list(line = list(color = "white", width = 0.5)),
        colorbar = list(title = "Ticks")
      ) %>%
      layout(geo = list(scope = "usa", projection = list(type = "albers usa"),
                        showlakes = FALSE, bgcolor = "rgba(0,0,0,0)"))
  })

  output$longitudinalPlot <- renderPlotly({
    NULL
  })

}
