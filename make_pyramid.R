library(tidyverse)

# Grade scales, one per discipline. Every scale goes into one ordered factor
# so the plot can place each facet on its own range of the y axis.
yds_levels <- c(
  paste0("5.", 0:9),
  paste0("5.", rep(10:15, each = 4), c("a", "b", "c", "d"))
)
aid_levels     <- paste0("A", 0:5)
boulder_levels <- c("V-easy", paste0("V", 0:17))
ice_levels     <- c(paste0("WI", 1:7), paste0("M", 1:13))

grade_levels <- c(yds_levels, aid_levels, boulder_levels, ice_levels)

# Normalize a YDS rating (e.g. "5.11-", "5.10a/b", "5.12", "5.9+ PG13")
normalize_yds <- function(rating) {
  yds <- str_extract(rating, "5\\.\\d+[abcd]?(/[abcd])?[+-]?")
  yds <- str_remove(yds, "/[abcd]")                       # 5.10a/b -> 5.10a
  yds <- str_replace(yds, "^(5\\.1\\d)-$", "\\1a")         # 5.11-   -> 5.11a
  yds <- str_replace(yds, "^(5\\.1\\d)\\+$", "\\1d")       # 5.11+   -> 5.11d
  yds <- str_remove(yds, "[+-]$")                         # 5.9+    -> 5.9
  yds <- str_replace(yds, "^(5\\.1\\d)$", "\\1a")            # 5.12    -> 5.12a
  yds
}

normalize_grade <- function(rating, route_type) {
  case_when(
    route_type == "Boulder" ~
      str_replace(str_extract(rating, "V(\\d+|-easy)"), "^V0?-easy$", "V-easy"),
    route_type == "Ice" ~
      coalesce(str_replace(str_extract(rating, "[AW]I\\d"), "^AI", "WI"),
               str_extract(rating, "M\\d+")),
    route_type == "Aid" ~
      coalesce(normalize_yds(rating),
               str_replace(str_extract(rating, "[AC]\\d"), "^C", "A")),
    TRUE ~ normalize_yds(rating)
  )
}

lead_style_colors <- c(
  "Onsight"   = "#0072B2",
  "Flash"     = "#56B4E9",
  "Redpoint"  = "#CC0000",
  "Pinkpoint" = "#CC79A7",
  "Top Rope"  = "#009E73",
  "Lead"      = "#E69F00",
  "Follow"    = "#F0E442",
  "Solo"      = "#000000",
  "Send"      = "#D55E00",
  "Attempt"   = "#999999"
)

# Turn a Mountain Project profile link (any page under /user/<id>/...) or a bare
# user ID into the climber's tick-export URL. The export needs the name part of
# the URL, so we follow Mountain Project's redirect from /user/<id> to get it.
resolve_mp_user <- function(text) {
  text <- str_trim(text)
  id   <- coalesce(str_match(text, "/user/(\\d+)")[, 2],
                   str_match(text, "^(\\d+)$")[, 2])
  if (is.na(id)) {
    stop("Couldn't find a user ID. Paste a link like ",
         "https://www.mountainproject.com/user/123456789/your-name")
  }

  resp <- httr::HEAD(paste0("https://www.mountainproject.com/user/", id),
                     httr::timeout(15))
  slug <- str_match(resp$url, "/user/\\d+/([^/?#]+)")[, 2]
  if (httr::status_code(resp) != 200 || is.na(slug)) {
    stop("No Mountain Project user found with ID ", id, ".")
  }

  list(
    name = str_to_title(str_replace_all(slug, "-", " ")),
    url  = paste0("https://www.mountainproject.com/user/", id, "/", slug, "/tick-export")
  )
}

process_ticks <- function(filepath) {
  read_csv(filepath, show_col_types = FALSE) %>%
    janitor::clean_names() %>%
    mutate(
      route_type = case_when(
        str_detect(route_type, "Boulder")   ~ "Boulder",
        str_detect(route_type, "Ice|Mixed") ~ "Ice",
        str_detect(route_type, "Aid")       ~ "Aid",
        str_detect(route_type, "Sport")     ~ "Sport",
        route_type == "TR"                  ~ "Toprope",
        TRUE                                ~ "Trad"
      ),
      rating_new = factor(normalize_grade(rating, route_type), levels = grade_levels),
      year       = as.integer(format(date, "%Y")),
      state      = str_trim(str_extract(location, "^[^>]+")),
      area       = str_trim(str_match(location, "^[^>]+>([^>]+)")[, 2]),
      lead_style = case_when(
        route_type == "Boulder" ~ style,
        is.na(lead_style)       ~ "Top Rope",
        TRUE                    ~ lead_style
      )
    )
}
