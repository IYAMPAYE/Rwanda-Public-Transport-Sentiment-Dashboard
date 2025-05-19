library(shiny)
library(shinydashboard)
library(highcharter)
library(plotly)
library(DT)
library(lubridate)
library(tidytext)
library(shinyjs)
library(shinyWidgets)
library(leaflet)
library(dplyr)
library(sf)
library(rnaturalearth)# Sample data generation with enhanced dataset
generate_sample_data <- function() {
  set.seed(123)
  dates <- seq.Date(from = as.Date("2024-01-01"), to = as.Date("2024-12-31"), by = "day")
  n <- length(dates)
  
  # Rwanda's districts by province
  districts <- list(
    "Kigali" = c("Nyarugenge", "Gasabo", "Kicukiro"),
    "Eastern" = c("Bugesera", "Gatsibo", "Kayonza", "Kirehe", "Ngoma", "Nyagatare", "Rwamagana"),
    "Western" = c("Karongi", "Ngororero", "Nyabihu", "Nyamasheke", "Rubavu", "Rusizi", "Rutsiro"),
    "Northern" = c("Burera", "Gakenke", "Gicumbi", "Musanze", "Rulindo"),
    "Southern" = c("Gisagara", "Huye", "Kamonyi", "Muhanga", "Nyamagabe", "Nyanza", "Nyaruguru", "Ruhango")
  )
  
  # Flatten the districts list
  all_districts <- unlist(districts)
  
  transport_types <- c("Bus", "Taxi", "Motorcycle", "Bicycle", "Walking")
  
  data <- data.frame(
    date = dates,
    positive = round(runif(n, 20, 50)),
    neutral = round(runif(n, 30, 60)),
    negative = round(runif(n, 10, 40)),
    region = sample(names(districts), n, replace = TRUE),
    district = NA,  # Will fill this next
    source = sample(c("Twitter", "Facebook", "News Comments", "Surveys"), n, replace = TRUE),
    transport_type = sample(transport_types, n, replace = TRUE),
    comment = sapply(1:n, function(x) {
      paste(sample(c(
        "price too high", "fair system", "long wait", "convenient", 
        "confusing", "better service", "comfortable", "unreliable",
        "affordable", "expensive", "clean", "dirty", "safe", "dangerous"
      ), sample(3:8, 1), replace = TRUE), collapse = " ")
    }),
    stringsAsFactors = FALSE
  )
  
  # Assign districts based on region
  for (i in 1:nrow(data)) {
    region_name <- data$region[i]
    data$district[i] <- sample(districts[[region_name]], 1)
  }
  
  return(data)
}

sentiment_data <- generate_sample_data()

# Create Rwanda district shapefile data
rwanda_sf <- function() {
  # This function returns a simplified Rwanda district shapefile
  # In a real application, you would load actual shapefile data
  
  # 30 districts of Rwanda with approximate coordinates
  districts <- data.frame(
    district = c(
      # Kigali Province
      "Nyarugenge", "Gasabo", "Kicukiro",
      # Eastern Province
      "Bugesera", "Gatsibo", "Kayonza", "Kirehe", "Ngoma", "Nyagatare", "Rwamagana",
      # Western Province
      "Karongi", "Ngororero", "Nyabihu", "Nyamasheke", "Rubavu", "Rusizi", "Rutsiro",
      # Northern Province
      "Burera", "Gakenke", "Gicumbi", "Musanze", "Rulindo",
      # Southern Province
      "Gisagara", "Huye", "Kamonyi", "Muhanga", "Nyamagabe", "Nyanza", "Nyaruguru", "Ruhango"
    ),
    province = c(
      rep("Kigali", 3),
      rep("Eastern", 7),
      rep("Western", 7),
      rep("Northern", 5),
      rep("Southern", 8)
    ),
    # Approximate centroids for districts (would be replaced with actual data)
    lon = c(
      30.061, 30.103, 30.082,  # Kigali
      30.250, 30.450, 30.650, 30.850, 30.450, 30.350, 30.350,  # Eastern
      29.450, 29.550, 29.500, 29.350, 29.370, 29.320, 29.400,  # Western
      29.830, 29.730, 30.050, 29.630, 29.880,  # Northern
      29.830, 29.750, 29.870, 29.750, 29.550, 29.750, 29.550, 29.750  # Southern
    ),
    lat = c(
      -1.950, -1.930, -1.970,  # Kigali
      -2.150, -1.950, -1.850, -2.270, -2.150, -1.450, -1.950,  # Eastern
      -2.100, -1.850, -1.650, -2.400, -1.700, -2.600, -1.950,  # Western
      -1.400, -1.700, -1.550, -1.500, -1.650,  # Northern
      -2.600, -2.550, -1.850, -2.080, -2.500, -2.350, -2.800, -2.200  # Southern
    )
  )
  
  # Create circular polygons around the centroids to simulate district boundaries
  # In a real application, you would load actual shapefile data instead
  sf_districts <- lapply(1:nrow(districts), function(i) {
    center <- c(districts$lon[i], districts$lat[i])
    # Create a circle of points around the center
    angle <- seq(0, 2*pi, length.out = 50)
    radius <- 0.05  # Approximately 5-6 km
    
    # Create a polygon
    coords <- cbind(
      center[1] + radius * cos(angle),
      center[2] + radius * sin(angle)
    )
    # Close the polygon
    coords <- rbind(coords, coords[1, ])
    
    # Create a simple polygon
    st_polygon(list(coords))
  })
  
  # Convert to sf object
  rwanda_sf <- st_sf(
    district = districts$district,
    province = districts$province,
    geometry = st_sfc(sf_districts, crs = 4326)
  )
  
  return(rwanda_sf)
}

# Load Rwanda shapefile
rwanda_districts <- rwanda_sf()

# UI Definition
ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css"),
    tags$script(src = "script.js"),
    tags$script(src = "https://cdn.jsdelivr.net/npm/shepherd.js@8.3.1/dist/js/shepherd.min.js"),
    tags$link(rel = "stylesheet", href = "https://cdn.jsdelivr.net/npm/shepherd.js@8.3.1/dist/css/shepherd.css")
  ),
  
  # Loading screen
  div(id = "loading-screen",
      div(class = "loading-content",
          h3("Loading Dashboard..."),
          div(class = "spinner")
      )
  ),
  
  # Notifications container
  div(id = "notifications-container"),
  
  # Theme toggle and help button
  div(class = "header-controls",
      div(class = "theme-toggle-container",
          materialSwitch(inputId = "theme_toggle", 
                         label = "Dark Mode", 
                         status = "primary",
                         right = TRUE)
      ),
      actionButton("help_btn", "Help Tour", icon = icon("question-circle"), 
                   class = "btn-help")
  ),
  
  titlePanel(div(class = "app-title", "Rwanda Public Transport Sentiment Analysis")),
  
  # Filters row
  fluidRow(
    column(3,
           dateRangeInput("date_range", "Select Date Range:",
                          start = min(sentiment_data$date),
                          end = max(sentiment_data$date),
                          separator = "to")
    ),
    column(3,
           pickerInput("regions", "Filter Provinces:",
                       choices = unique(sentiment_data$region),
                       selected = unique(sentiment_data$region),
                       multiple = TRUE,
                       options = list(`actions-box` = TRUE,
                                      `live-search` = TRUE))
    ),
    column(3,
           pickerInput("districts", "Filter Districts:",
                       choices = unique(sentiment_data$district),
                       selected = unique(sentiment_data$district),
                       multiple = TRUE,
                       options = list(`actions-box` = TRUE,
                                      `live-search` = TRUE))
    ),
    column(3,
           pickerInput("sources", "Filter Data Sources:",
                       choices = unique(sentiment_data$source),
                       selected = unique(sentiment_data$source),
                       multiple = TRUE,
                       options = list(`actions-box` = TRUE))
    )
  ),
  
  tabsetPanel(
    id = "main_tabs",
    type = "pills",
    
    # Dashboard Tab
    tabPanel(
      "Overview",
      icon = icon("dashboard"),
      fluidRow(
        column(4, valueBoxOutput("positive_box", width = 12)),
        column(4, valueBoxOutput("neutral_box", width = 12)),
        column(4, valueBoxOutput("negative_box", width = 12))
      ),
      
      fluidRow(
        column(6, highchartOutput("sentiment_pie")),
        column(6, plotlyOutput("wordcloud"))
      ),
      
      fluidRow(
        column(12, leafletOutput("district_map", height = "500px"))
      ),
      
      fluidRow(
        column(12, 
               div(class = "recent-comments",
                   h3("Recent Public Comments"),
                   uiOutput("comments_list")))
      )
    ),
    
    # Trend Analysis Tab
    tabPanel(
      "Trends",
      icon = icon("chart-line"),
      fluidRow(
        column(12, highchartOutput("sentiment_trend"))
      ),
      fluidRow(
        column(6, plotlyOutput("source_plot")),
        column(6, highchartOutput("sentiment_by_week"))
      ),
      fluidRow(
        column(12, plotlyOutput("sentiment_breakdown"))
      )
    ),
    
    # Regional View Tab
    tabPanel(
      "Regional",
      icon = icon("map"),
      fluidRow(
        column(6, highchartOutput("region_heatmap")),
        column(6, plotlyOutput("region_bar"))
      ),
      fluidRow(
        column(12, highchartOutput("region_trend"))
      ),
      fluidRow(
        column(12, plotlyOutput("district_bars"))
      )
    ),
    
    # Data Explorer Tab
    tabPanel(
      "Data Explorer",
      icon = icon("table"),
      fluidRow(
        column(12, 
               downloadButton("export_data", "Export Data", class = "btn-download"),
               DTOutput("raw_data"))
      )
    )
  )
)

server <- function(input, output, session) {
  
  # Update district choices based on selected regions
  observe({
    if (length(input$regions) > 0) {
      region_districts <- sentiment_data %>%
        filter(region %in% input$regions) %>%
        pull(district) %>%
        unique()
      
      updatePickerInput(session, "districts",
                        choices = region_districts,
                        selected = intersect(input$districts, region_districts))
    } else {
      updatePickerInput(session, "districts",
                        choices = unique(sentiment_data$district),
                        selected = input$districts)
    }
  })
  
  # Theme switching
  observeEvent(input$theme_toggle, {
    session$sendCustomMessage(type = "toggleTheme", input$theme_toggle)
  })
  
  # Help tour
  observeEvent(input$help_btn, {
    session$sendCustomMessage(type = "startTour", "")
  })
  
  # Reactive data filtering
  filtered_data <- reactive({
    data <- sentiment_data %>%
      filter(date >= input$date_range[1] & date <= input$date_range[2],
             region %in% input$regions,
             district %in% input$districts,
             source %in% input$sources)
    data
  })
  
  # Value boxes
  output$positive_box <- renderValueBox({
    data <- filtered_data()
    valueBox(
      value = sum(data$positive),
      subtitle = "Positive Sentiment",
      icon = icon("thumbs-up"),
      color = ifelse(input$theme_toggle, "teal", "green")
    )
  })
  
  output$neutral_box <- renderValueBox({
    data <- filtered_data()
    valueBox(
      value = sum(data$neutral),
      subtitle = "Neutral Sentiment",
      icon = icon("meh"),
      color = ifelse(input$theme_toggle, "yellow", "orange")
    )
  })
  
  output$negative_box <- renderValueBox({
    data <- filtered_data()
    valueBox(
      value = sum(data$negative),
      subtitle = "Negative Sentiment",
      icon = icon("thumbs-down"),
      color = ifelse(input$theme_toggle, "red", "maroon")
    )
  })
  
  # Highcharts Pie Chart
  output$sentiment_pie <- renderHighchart({
    data <- filtered_data()
    summary <- data.frame(
      Sentiment = c("Positive", "Neutral", "Negative"),
      Count = c(sum(data$positive), sum(data$neutral), sum(data$negative)),
      color = c("#4CAF50", "#FFC107", "#F44336")
    )
    
    highchart() %>%
      hc_chart(type = "pie") %>%
      hc_add_series(
        data = lapply(1:nrow(summary), function(i) {
          list(
            name = summary$Sentiment[i],
            y = summary$Count[i],
            color = summary$color[i]
          )
        }),
        name = "Sentiment",
        dataLabels = list(enabled = TRUE, format = "{point.name}: {point.percentage:.1f}%")
      ) %>%
      hc_title(text = "Sentiment Distribution") %>%
      hc_tooltip(pointFormat = "<b>{point.y}</b> mentions")
  })
  
  # Plotly Word Cloud
  output$wordcloud <- renderPlotly({
    data <- filtered_data()
    
    words <- unlist(strsplit(tolower(data$comment), " "))
    words <- words[!words %in% stop_words$word]
    words <- gsub("[^a-z]", "", words)
    words <- words[nchar(words) > 3]
    
    word_freq <- as.data.frame(table(words))
    word_freq <- word_freq[order(-word_freq$Freq), ]
    top_words <- head(word_freq, 20)
    
    plot_ly(
      data = top_words,
      x = ~Freq,
      y = ~reorder(words, Freq),
      type = "bar",
      orientation = "h",
      marker = list(color = ifelse(input$theme_toggle, "#4CAF50", "#2196F3"))
    ) %>%
      layout(
        title = "Top 20 Mentioned Words",
        yaxis = list(title = "", categoryorder = "total ascending"),
        xaxis = list(title = "Frequency"),
        margin = list(l = 150)
      )
  })
  
  # District Map with Rwanda Shapefile
  output$district_map <- renderLeaflet({
    # Get sentiment data by district
    district_data <- filtered_data() %>%
      group_by(district) %>%
      summarize(
        positive = sum(positive),
        neutral = sum(neutral),
        negative = sum(negative),
        total = sum(positive) + sum(neutral) + sum(negative),
        sentiment_score = (sum(positive) - sum(negative)) / 
          (sum(positive) + sum(neutral) + sum(negative))
      )
    
    # Join with shapefile data
    map_data <- left_join(rwanda_districts, district_data, by = "district")
    
    # Replace NA values with 0
    map_data$sentiment_score[is.na(map_data$sentiment_score)] <- 0
    
    # Create color palette for sentiment scores
    pal <- colorNumeric(
      palette = "RdYlGn",
      domain = c(-1, 1)
    )
    
    # Create labels for districts
    labels <- sprintf(
      "<strong>%s District</strong><br/>Province: %s<br/>Sentiment Score: %s<br/>Positive: %s<br/>Neutral: %s<br/>Negative: %s",
      map_data$district,
      map_data$province,
      round(map_data$sentiment_score, 2),
      map_data$positive,
      map_data$neutral, 
      map_data$negative
    ) %>% lapply(htmltools::HTML)
    
    # Create the map
    leaflet(map_data) %>%
      addTiles() %>%
      setView(lng = 29.9, lat = -2.0, zoom = 8) %>%
      addPolygons(
        fillColor = ~pal(sentiment_score),
        weight = 2,
        opacity = 1,
        color = "white",
        dashArray = "3",
        fillOpacity = 0.7,
        highlight = highlightOptions(
          weight = 5,
          color = "#666",
          dashArray = "",
          fillOpacity = 0.7,
          bringToFront = TRUE
        ),
        label = labels,
        labelOptions = labelOptions(
          style = list("font-weight" = "normal", padding = "3px 8px"),
          textsize = "15px",
          direction = "auto"
        )
      ) %>%
      addLegend(
        position = "bottomright",
        pal = pal,
        values = ~sentiment_score,
        title = "Sentiment Score",
        opacity = 0.7
      )
  })
  

  
  # Recent comments list
  output$comments_list <- renderUI({
    data <- filtered_data()
    recent_comments <- head(data[order(data$date, decreasing = TRUE), ], 10)
    
    tagList(
      lapply(1:nrow(recent_comments), function(i) {
        sentiment_score <- (recent_comments$positive[i] - recent_comments$negative[i]) / 
          (recent_comments$positive[i] + recent_comments$neutral[i] + recent_comments$negative[i])
        
        sentiment_color <- if (sentiment_score > 0.1) {
          "#4CAF50"
        } else if (sentiment_score < -0.1) {
          "#F44336"
        } else {
          "#FFC107"
        }
        
        div(
          class = "comment-box",
          style = paste("border-left: 4px solid", sentiment_color),
          div(class = "comment-meta",
              strong(format(recent_comments$date[i], "%b %d, %Y")), 
              span(class = "comment-source", 
                   paste(recent_comments$source[i], "-", 
                         recent_comments$district[i], ", ",
                         recent_comments$region[i], " Province"))
          ),
          div(class = "comment-text", recent_comments$comment[i]),
          div(class = "comment-transport",
              icon("bus"), 
              span(recent_comments$transport_type[i]))
        )
      })
    )
  })
  
  # Highcharts Trend Plot
  output$sentiment_trend <- renderHighchart({
    data <- filtered_data()
    daily <- aggregate(cbind(positive, neutral, negative) ~ date, data, sum)
    
    highchart() %>%
      hc_chart(type = "line") %>%
      hc_title(text = "Sentiment Trend Over Time") %>%
      hc_xAxis(type = "datetime") %>%
      hc_yAxis(title = list(text = "Number of Mentions")) %>%
      hc_add_series(name = "Positive", data = daily$positive, color = "#4CAF50") %>%
      hc_add_series(name = "Neutral", data = daily$neutral, color = "#FFC107") %>%
      hc_add_series(name = "Negative", data = daily$negative, color = "#F44336") %>%
      hc_tooltip(shared = TRUE, crosshairs = TRUE) %>%
      hc_legend(enabled = TRUE)
  })
  
  # Sentiment Breakdown by Words
  output$sentiment_breakdown <- renderPlotly({
    data <- filtered_data() %>%
      unnest_tokens(word, comment) %>%
      anti_join(stop_words) %>%
      inner_join(get_sentiments("bing")) %>%
      count(sentiment, word, sort = TRUE) %>%
      group_by(sentiment) %>%
      top_n(10, n) %>%
      ungroup()
    
    plot_ly(data, x = ~n, y = ~reorder(word, n), 
            color = ~sentiment, colors = c("#F44336", "#4CAF50"),
            type = "bar") %>%
      layout(title = "Top Positive/Negative Words",
             yaxis = list(title = ""),
             barmode = "group")
  })
  
  # Plotly Source Plot
  output$source_plot <- renderPlotly({
    data <- filtered_data()
    source_summary <- aggregate(cbind(positive, neutral, negative) ~ source, data, sum)
    
    plot_ly(source_summary, x = ~source, y = ~positive, type = 'bar', name = 'Positive',
            marker = list(color = "#4CAF50")) %>%
      add_trace(y = ~neutral, name = 'Neutral', marker = list(color = "#FFC107")) %>%
      add_trace(y = ~negative, name = 'Negative', marker = list(color = "#F44336")) %>%
      layout(
        title = "Sentiment by Data Source",
        yaxis = list(title = "Number of Mentions"),
        xaxis = list(title = ""),
        barmode = 'stack'
      )
  })
  
  # Highcharts Weekly Pattern
  output$sentiment_by_week <- renderHighchart({
    data <- filtered_data()
    data$weekday <- weekdays(data$date)
    weekday_summary <- aggregate(cbind(positive, neutral, negative) ~ weekday, data, mean)
    
    weekday_order <- c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")
    weekday_summary$weekday <- factor(weekday_summary$weekday, levels = weekday_order)
    weekday_summary <- weekday_summary[order(weekday_summary$weekday), ]
    
    highchart() %>%
      hc_chart(type = "column") %>%
      hc_title(text = "Average Sentiment by Weekday") %>%
      hc_xAxis(categories = weekday_summary$weekday) %>%
      hc_yAxis(title = list(text = "Average Mentions")) %>%
      hc_add_series(name = "Positive", data = weekday_summary$positive, color = "#4CAF50") %>%
      hc_add_series(name = "Neutral", data = weekday_summary$neutral, color = "#FFC107") %>%
      hc_add_series(name = "Negative", data = weekday_summary$negative, color = "#F44336") %>%
      hc_plotOptions(column = list(stacking = "normal")) %>%
      hc_tooltip(shared = TRUE)
  })
  
  # Highcharts Region Heatmap
  output$region_heatmap <- renderHighchart({
    data <- filtered_data()
    region_summary <- aggregate(cbind(positive, neutral, negative) ~ region, data, sum)
    region_summary$total <- rowSums(region_summary[, c("positive", "neutral", "negative")])
    region_summary$sentiment_score <- (region_summary$positive - region_summary$negative) / region_summary$total
    
    highchart() %>%
      hc_chart(type = "heatmap") %>%
      hc_title(text = "Provincial Sentiment Heatmap") %>%
      hc_colorAxis(stops = color_stops(3, c("#F44336", "#FFFFFF", "#4CAF50"))) %>%
      hc_add_series(
        name = "Sentiment Score",
        data = list_parse2(data.frame(region_summary$region, 1, round(region_summary$sentiment_score, 2)))
      ) %>%
      hc_xAxis(categories = region_summary$region, title = NULL) %>%
      hc_yAxis(categories = "", title = NULL) %>%
      hc_tooltip(formatter = JS("function() {
        return '<b>' + this.point.name + '</b>: ' + this.point.value;
      }"))
  })
  
  # Plotly Region Bar Plot
  output$region_bar <- renderPlotly({
    data <- filtered_data()
    region_summary <- aggregate(cbind(positive, neutral, negative) ~ region, data, sum)
    
    plot_ly(region_summary, x = ~region, y = ~positive, type = 'bar', name = 'Positive',
            marker = list(color = "#4CAF50")) %>%
      add_trace(y = ~neutral, name = 'Neutral', marker = list(color = "#FFC107")) %>%
      add_trace(y = ~negative, name = 'Negative', marker = list(color = "#F44336")) %>%
      layout(
        title = "Sentiment by Province",
        yaxis = list(title = "Number of Mentions"),
        xaxis = list(title = ""),
        barmode = 'group'
      )
  })
  
  # New District Bar Chart
  output$district_bars <- renderPlotly({
    data <- filtered_data()
    district_summary <- aggregate(cbind(positive, neutral, negative) ~ district + region, data, sum)
    district_summary$sentiment_score <- (district_summary$positive - district_summary$negative) / 
      (district_summary$positive + district_summary$neutral + district_summary$negative)
    district_summary <- district_summary[order(district_summary$region, district_summary$sentiment_score), ]
    
    plot_ly(district_summary, x = ~district, y = ~sentiment_score, 
            type = 'bar', color = ~region,
            text = ~paste0("Province: ", region, 
                           "<br>Score: ", round(sentiment_score, 2),
                           "<br>Positive: ", positive,
                           "<br>Neutral: ", neutral,
                           "<br>Negative: ", negative)) %>%
      layout(
        title = "Sentiment Score by District and Province",
        yaxis = list(title = "Sentiment Score (-1 to 1)"),
        xaxis = list(title = "", categoryorder = "array", 
                     categoryarray = district_summary$district),
        hovermode = "closest"
      )
  })
  
  # Highcharts Region Trend
  output$region_trend <- renderHighchart({
    data <- filtered_data()
    data$month <- format(data$date, "%Y-%m")
    region_monthly <- aggregate(cbind(positive, neutral, negative) ~ month + region, data, sum)
    
    regions <- unique(region_monthly$region)
    
    hc <- highchart() %>%
      hc_chart(type = "line") %>%
      hc_title(text = "Provincial Sentiment Trends Over Time") %>%
      hc_xAxis(categories = unique(region_monthly$month)) %>%
      hc_yAxis(title = list(text = "Net Sentiment (Positive - Negative)"))
    
    for (region in regions) {
      region_data <- region_monthly[region_monthly$region == region, ]
      hc <- hc %>% 
        hc_add_series(name = region, 
                      data = region_data$positive - region_data$negative,
                      color = ifelse(mean(region_data$positive - region_data$negative) > 0, 
                                     "#4CAF50", "#F44336"))
    }
    
    hc %>% hc_tooltip(shared = TRUE)
  })
  
  # Data Table
  output$raw_data <- renderDT({
    datatable(
      filtered_data(),
      extensions = 'Buttons',
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel', 'pdf', 'print'),
        searching = TRUE,
        ordering = TRUE
      )
    )
  })
  
  # Data Export
  output$export_data <- downloadHandler(
    filename = function() {
      paste("sentiment-data-", Sys.Date(), ".csv", sep="")
    },
    content = function(file) {
      write.csv(filtered_data(), file, row.names = FALSE)
    }
  )
}

shinyApp(ui, server)