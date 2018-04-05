## Get summary stats of a single (or multiple single) day/s

library(RSQLite)
library(tidyverse)
library(dbplyr)
library(lubridate)

db <- 'data/history.db'
con <- dbConnect(SQLite(), db)
trip_updates <- tbl(con, 'trip_updates')

## average trip delay by trip (start) time
trip.delays <-
    trip_updates %>%
    filter(!is.na(departure_delay)) %>%
    group_by(trip_id) %>%
    summarise(time = min(timestamp, na.rm = TRUE),
              delay = mean(departure_delay, na.rm = TRUE)) %>%
    arrange(time)


## peak vs offpeak ontimeness
peak <- list(morning = c(7.5, 10),
             evening = c(15, 19))

tu <- trip_updates %>%
    select(timestamp, departure_delay) %>%
    filter(!is.na(departure_delay)) %>%
    rename(delay = departure_delay) %>%
    mutate(ontime = case_when(delay < -60 ~ 'early',
                              delay > 300 ~ 'late',
                              TRUE ~ 'ontime')) %>%
    collect() %>%
    mutate(timestamp = as_datetime(as.POSIXct(timestamp, origin = '1970-01-01')),
           time = hour(timestamp) + minute(timestamp) / 60,
           peak = case_when(between(time, peak$morning[1], peak$morning[2]) ~ 'morning',
                            between(time, peak$evening[1], peak$evening[2]) ~ 'evening',
                            between(time, peak$morning[2], peak$evening[1]) ~ 'offpeak',
                            TRUE ~ '')) %>%
    filter(peak != '')

tu %>% group_by(peak) %>%
    summarize(pct = mean(ontime == 'ontime')) %>%
    print


