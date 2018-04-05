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
    filter(!is.na(departure_delay) & stop_sequence > 1) %>%
    group_by(trip_id) %>%
    summarise(time = min(timestamp, na.rm = TRUE),
              delay = mean(departure_delay, na.rm = TRUE)) %>%
    arrange(time) %>%
    collect() %>%
    mutate(time = as_datetime(as.POSIXct(time, origin = '1970-01-01')))

ggplot(trip.delays, aes(x = time, y = delay)) +
    geom_point(alpha = 0.5) +
    ylim(-30 * 60, 30 * 60) +
    geom_hline(yintercept = c(-60, 300), lty = 2, col = 'red')

## peak vs offpeak ontimeness
peak <- list(morning = c(7.5, 10),
             evening = c(15, 19))

tu <- trip_updates %>%
    select(timestamp, departure_delay, stop_sequence) %>%
    filter(!is.na(departure_delay)) %>%
    rename(delay = departure_delay) %>%
    mutate(ontime = case_when(delay < -60 ~ 'early',
                              delay > 300 ~ 'late',
                              TRUE ~ 'ontime')) %>%
    collect() %>%
    mutate(timestamp = as.POSIXct(timestamp, origin = '1970-01-01'),
           ##time = hour(timestamp) + minute(timestamp) / 60,
           time = as.numeric(format(timestamp, '%H')) +
               as.numeric(format(timestamp, '%M')) / 60,
           peak = case_when(between(time, peak$morning[1], peak$morning[2]) ~ 'morning peak',
                            between(time, peak$evening[1], peak$evening[2]) ~ 'evening peak',
                            between(time, peak$morning[2], peak$evening[1]) ~ 'off peak',
                            TRUE ~ '')) %>%
    filter(peak != '')

smry <- tu %>%
    filter(delay > -20000 & stop_sequence < 85) %>%
    group_by(peak, stop_sequence) %>%
    summarize(late = mean(ontime == 'late'),
              early = mean(ontime == 'early'),
              ontime = mean(ontime == 'ontime'))

p <- ggplot(smry, aes(x = stop_sequence, colour = peak)) +
    ylim(0, 1) + xlab('Stop #') + labs(colour = '')
p + geom_point(aes(y = ontime)) + ylab('% buses on time (1 min early - 5 min late)')
p + geom_point(aes(y = late)) + ylab('% buses > 5min late')
p + geom_point(aes(y = early)) + ylab('% buses > 1min early')

ggplot(tu, aes(x = time, y = delay)) +
    geom_point()

