## Get summary stats of a single (or multiple single) day/s

library(RSQLite)
library(tidyverse)
library(dbplyr)
library(lubridate)
library(ggmap)
library(viridis)


load('summary.rda')

dows <- c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday",
          "Saturday", "Sunday")
smry.overall <- do.call(
    bind_rows,
    lapply(names(daysmry$overall),
           function(x)
               daysmry$overall[[x]] %>%
               add_column(date = ymd(x), .before = 1))) %>%
    mutate(dow = date %>% format("%A") %>%
               factor(levels = dows))

p1 <- ggplot(smry.overall, aes(date)) +
    geom_line(aes(y = percent_ontime*100)) +
    geom_point(aes(y = percent_ontime*100, size = n))# +
#    ylim(0, 100)

p1
p1 + facet_grid(dow~.)



smry.peak <- do.call(
    bind_rows,
    lapply(names(daysmry$peak),
           function(x)
               daysmry$peak[[x]] %>%
               filter(peak != "") %>%
               add_column(date = ymd(x), .before = 1))) %>%
    mutate(dow = date %>% format("%A") %>%
               factor(levels = dows))

p2 <- ggplot(smry.peak, aes(date, group = peak, colour = peak)) +
    geom_line(aes(y = percent_ontime * 100)) +
    geom_point(aes(y = percent_ontime * 100, size = n))# +
#ylim(0, 100)

p2
p2 + facet_grid(dow~.)



smry.stop <- do.call(
    bind_rows,
    lapply(names(daysmry$stop),
           function(x)
               daysmry$stop[[x]] %>%
               add_column(date = ymd(x), .before = 1))) %>%
    mutate(dow = date %>% format("%A") %>%
               factor(levels = dows))

p3.1 <- ggplot(smry.stop %>% filter(stop_sequence == 1),
               aes(date)) +
    geom_line(aes(y = percent_ontime * 100)) +
    geom_line(aes(y = percent_early * 100), colour = "blue") +
    geom_line(aes(y = percent_late * 100), colour = "orangered") +
    ##geom_point(aes(y = percent_ontime * 100, size = n)) +
    ##ylim(0, 100) +
    xlab("Date") + ylab("Percent %") + ggtitle("First stop performance") +
    scale_y_continuous(breaks = 20*0:5,  expand = c(0, 0)) +
    geom_text(aes(x = date, y = val*100, label = text),
              data = tibble(
                  date = min(smry.stop$date),
                  val = smry.stop %>%
                      filter(stop_sequence == 1 &
                             date == min(smry.stop$date)) %>%
                      select(percent_ontime, percent_early, percent_late) %>%
                      as.numeric,
                  text = c("ontime", "early", "late")), nudge_x = -12)

p3.1 + geom_vline(xintercept = as.Date("2017-10-17"), col = "magenta", lty = 2)
p3.1 + facet_grid(dow~.)

p3.2 <- ggplot(smry.stop %>% filter(stop_sequence == 2),
               aes(date)) +
    geom_line(aes(y = percent_ontime * 100)) +
    geom_line(aes(y = percent_early * 100), colour = "blue") +
    geom_line(aes(y = percent_late * 100), colour = "orangered") +
    ##geom_point(aes(y = percent_ontime * 100, size = n)) +
    ##ylim(0, 100) +
    xlab("Date") + ylab("Percent %") + ggtitle("Second stop performance") +
    scale_y_continuous(breaks = 20*0:5, limits = c(0, 100), expand = c(0, 0)) +
    geom_text(aes(x = date, y = val*100, label = text),
              data = tibble(
                  date = min(smry.stop$date),
                  val = smry.stop %>%
                      filter(stop_sequence == 1 &
                             date == min(smry.stop$date)) %>%
                      select(percent_ontime, percent_early, percent_late) %>%
                      as.numeric,
                  text = c("ontime", "early", "late")), nudge_x = -12)

p3.2
p3.2 + facet_grid(dow~.)


p3.3 <- ggplot(smry.stop %>% filter(stop_sequence == 3),
               aes(date)) +
    geom_line(aes(y = percent_ontime * 100)) +
    geom_line(aes(y = percent_early * 100), colour = "blue") +
    geom_line(aes(y = percent_late * 100), colour = "orangered") +
    ##geom_point(aes(y = percent_ontime * 100, size = n)) +
    ##ylim(0, 100) +
    xlab("Date") + ylab("Percent %") + ggtitle("Third stop performance") +
    scale_y_continuous(breaks = 20*0:5, limits = c(0, 100), expand = c(0, 0)) +
    geom_text(aes(x = date, y = val*100, label = text),
              data = tibble(
                  date = min(smry.stop$date),
                  val = smry.stop %>%
                      filter(stop_sequence == 1 &
                             date == min(smry.stop$date)) %>%
                      select(percent_ontime, percent_early, percent_late) %>%
                      as.numeric,
                  text = c("ontime", "early", "late")), nudge_x = -12)

p3.3
p3.3 + facet_grid(dow~.)





p3 <- ggplot(smry.stop %>% filter(stop_sequence < 21),
             aes(stop_sequence)) + #, colour = date %>% as.factor)) +
    geom_line(aes(y = percent_ontime * 100, group = date)) + 
    geom_point(aes(y = percent_ontime * 100)) ##, size = n)) +
    #ylim(0, 100) +
    #scale_colour_viridis()

p3
p3 + facet_wrap(~dow)


smry.peak.stop <- do.call(
    bind_rows,
    lapply(names(daysmry$peak.stop),
           function(x)
               daysmry$peak.stop[[x]] %>%
               filter(peak != "") %>%
               add_column(date = ymd(x), .before = 1))) %>%
    mutate(dow = date %>% format("%A") %>%
               factor(levels = dows)) %>%
    ungroup

p4.1 <- ggplot(smry.peak.stop %>% filter(stop_sequence == 1),
               aes(date, colour = peak)) +
    geom_line(aes(y = percent_ontime * 100)) +
    geom_point(aes(y = percent_ontime * 100, size = n))

p4.1
p4.1 + facet_grid(dow~.)

p4 <- ggplot(smry.peak.stop %>% filter(stop_sequence < 31) %>%
             mutate(BREAK = ifelse(date >= ymd("2017-10-17"), 'after', 'before') %>%
                        factor(levels = c('before', 'after'))),
             aes(stop_sequence, colour = BREAK)) + 
    geom_line(aes(y = percent_ontime * 100,
                  group = interaction(peak, date))) +
    geom_point(aes(y = percent_ontime * 100))

p4 + facet_grid(~peak)
p4 + facet_grid(~ dow) + theme(legend.position = 'bottom')
p4 + facet_grid(peak~ dow) + theme(legend.position = 'bottom')


### Combined ontime/early/late
smry.all <- smry.peak.stop %>%
    gather('delay', 'percent', percent_ontime, percent_early, percent_late)

ggplot(smry.all %>% filter(stop_sequence == 1) %>%
       mutate(BREAK = factor(ifelse(date >= ymd("2017-10-17"), "after", "before"),
                             levels = c("before", "after"))),
       aes(date, percent * 100, colour = delay)) +
    geom_line(aes(group = interaction(delay))) +
    facet_grid(peak~.)



### Modeling
fit <- glm(percent_ontime ~ peak * poly(stop_sequence-1,7) * dow,
           data = smry.peak.stop, family = binomial,
           weights = n)
summary(fit)

smry.peak.stop <- smry.peak.stop %>%
    mutate(phat = predict(fit, type = "response"),
           pse = predict(fit, type = "response", se.fit = TRUE)$se.fit)

ggplot(smry.peak.stop %>% filter(stop_sequence < 31),
       aes(stop_sequence, colour = peak)) +
    geom_line(aes(y = percent_ontime * 100, alpha = 0.5,
                  group = interaction(peak,date))) +
    geom_ribbon(aes(ymin = 100*(phat - 1.96*pse),
                    ymax = 100*(phat + 1.96*pse),
                    fill = peak), alpha = 1) +
    facet_wrap( ~ dow)






########### The old script
library(tidyverse)
library(ggplot2)
library(RSQLite)
library(dbplyr)
library(viridis)

db <- 'data/history.db'
con <- dbConnect(SQLite(), db)

DATE <- "2017-10-16" %>% as.Date
daterange <- as.POSIXct(paste(DATE + 0:2, "00:00:00"))
tr <- as.numeric(daterange)
trip_updates <-
    tbl(con, 'trip_updates') %>%
    filter(between(timestamp, tr[1], tr[2]))

peak <- list(morning = c(6, 9.5),
             evening = c(14.5, 19))

## not very useful
ggplot(trip_updates, aes(as.POSIXct(timestamp, origin = "1970-01-01"))) +
    geom_point(aes(y = departure_delay / 60)) +
    ggtitle(format(DATE, "%A, %e %B %Y")) + xlab("Time") + ylab("Delay (minutes)")
    # geom_point(aes(y = arrival_delay), col = viridis(2)[1]) +

## average trip delay by trip (start) time
trip.delays <-
    trip_updates %>% collect() %>%
    mutate(timestamp = as.POSIXct(timestamp, origin = "1970-01-01"),
           date = format(timestamp, "%Y-%m-%d")) %>%
    filter(!is.na(departure_delay) & stop_sequence > 1) %>%
    group_by(date, trip_id) %>%
    summarise(time = min(timestamp, na.rm = TRUE),
              delay = mean(departure_delay, na.rm = TRUE)) %>%
    arrange(time) %>%
    mutate(timestamp = as.POSIXct(time, origin = '1970-01-01'),
           time = as.numeric(format(timestamp, '%H')) +
               as.numeric(format(timestamp, '%M')) / 60)

ggplot(trip.delays, aes(x = time, y = delay/60, colour = date)) +
    geom_point(alpha = 0.5) +
    ylim(-30, 30) +
    xlab("Time") + ylab("Delay (min)") +
    geom_hline(yintercept = c(-1, 5), lty = 2, col = 'red') +
    geom_vline(xintercept = do.call(c, peak), lty = 2, col = 'blue') +
    ggtitle(format(DATE, "%A, %e %B %Y"))

## peak vs offpeak ontimeness

tu <- trip_updates %>%
    select(timestamp, departure_delay, stop_sequence) %>%
    filter(!is.na(departure_delay)) %>%
    rename(delay = departure_delay) %>%
    mutate(ontime = case_when(delay < -60 ~ 'early',
                              delay > 300 ~ 'late',
                              TRUE ~ 'ontime')) %>%
    collect() %>%
    mutate(timestamp = as.POSIXct(timestamp, origin = '1970-01-01'),
           date = format(timestamp, "%Y-%m-%d"),
           time = as.numeric(format(timestamp, '%H')) +
               as.numeric(format(timestamp, '%M')) / 60,
           peak = case_when(between(time, peak$morning[1], peak$morning[2]) ~ 'morning peak',
                            between(time, peak$evening[1], peak$evening[2]) ~ 'evening peak',
                            between(time, peak$morning[2], peak$evening[1]) ~ 'off peak',
                            TRUE ~ '')) %>%
    filter(peak != '')

tu %>% filter(delay > -20000 & stop_sequence < 85) %>%
    group_by(date, peak) %>%
    summarize(late = mean(ontime == 'late'),
              late.n = sum(ontime == 'late'),
              late.se = sqrt(late * (1 - late) / late.n),
              early = mean(ontime == 'early'),
              early.n = sum(ontime == 'early'),
              early.se = sqrt(early * (1 - early) / early.n),
              on.time = mean(ontime == 'ontime'),
              on.time.n = sum(ontime == 'ontime'),
              on.time.se = sqrt(on.time * (1 - on.time) / on.time.n))


smry <- tu %>%
    filter(delay > -20000 & stop_sequence < 60) %>%
    group_by(date, peak, stop_sequence) %>%
    summarize(late = mean(ontime == 'late'),
              late.n = sum(ontime == 'late'),
              late.se = sqrt(late * (1 - late) / late.n),
              early = mean(ontime == 'early'),
              early.n = sum(ontime == 'early'),
              early.se = sqrt(early * (1 - early) / early.n),
              on.time = mean(ontime == 'ontime'),
              on.time.n = sum(ontime == 'ontime'),
              on.time.se = sqrt(on.time * (1 - on.time) / on.time.n)) %>%
    ungroup() %>%
    mutate(peak = as.factor(peak))
smry

p <- ggplot(smry, aes(x = stop_sequence, colour = peak,
                    #  lty = date,
                      group = interaction(date, peak))) +
    xlab('Stop #') + labs(colour = '') +
    theme(legend.position = 'none') +
    scale_y_continuous(labels = function(x) paste0(x * 100, '%'), limits = c(0, 1))

gridExtra::grid.arrange(
    p + geom_line(aes(y = late)) + ylab('5+ min late') +
    ggtitle(format(DATE, "%A, %e %B %Y")),
    p + geom_line(aes(y = on.time)) + ylab('On time'),
    p + geom_line(aes(y = early)) + ylab('1+ min early') +
    theme(legend.position = 'bottom'),
    nrow = 3)


pontime <- p + 
    geom_errorbar(aes(ymin = on.time - on.time.se, ymax = on.time + on.time.se)) + 
    ylab('On time (1 min early - 5 min late)')
plate <- p + 
    geom_errorbar(aes(ymin = late - late.se, ymax = late + late.se)) + 
    ylab('Late by 5+ min')
pearly <- p + 
    geom_errorbar(aes(ymin = early - early.se, ymax = early + early.se)) + 
    ylab('Early by 1+ min')

gridExtra::grid.arrange(plate, pontime, pearly, nrow=3)


ggplot(tu, aes(x = time, y = delay/60/60)) +
    geom_point() +
    ylab("Delay [HOURS!!]")



## Load stops into database
if (!dbExistsTable(con, 'stops')) {
    url <- "https://cdn01.at.govt.nz/data/stops.txt"
    st <- read_csv(url)
    vid <- unique(gsub(".+_v", "", st$stop_id))[1]
    st <- st[grepl(vid, st$stop_id), ]
    st$stop_id <- gsub("-.+", "", st$stop_id)
    dbWriteTable(con, 'stops', st, overwrite = TRUE)
}
stops_tbl <- tbl(con, 'stops') %>%
    select(stop_id, stop_lat, stop_lon) %>% collect()

stopdelays <- trip_updates %>%
    select(stop_id, departure_delay) %>%
    filter(!is.na(departure_delay) & departure_delay > -60*60 & 
        departure_delay < 60 * 60) %>%
    group_by(stop_id) %>%
    summarize(delay = mean(departure_delay, na.rm = TRUE)) %>%
    collect() %>%
    mutate(stop_id = gsub("-.+", "", stop_id)) %>%
    inner_join(stops_tbl, by = "stop_id") %>%
    mutate(ontime = case_when(delay < 0 ~ 'early',
                              delay >= 0 ~ 'late',
                              TRUE ~ 'ontime'))

xr <- quantile(stopdelays$stop_lon, c(0.25, 0.75)) %>% as.numeric
## extendrange(stopdelays$stop_lon)
yr <- quantile(stopdelays$stop_lat, c(0.25, 0.75)) %>% as.numeric
## extendrange(stopdelays$stop_lat)
bbox <- c(xr[1], yr[1], xr[2], yr[2])
akl <- get_stamenmap(bbox = bbox, zoom = 13,  maptype = "toner-lite")

dlymax <- max(abs(stopdelays$delay/60))
ggmap(akl) +
    geom_point(aes(x = stop_lon, y = stop_lat, color = delay/60,
                   size = abs(delay/60)),
               data = stopdelays %>% filter(ontime != 'ontime')) +
    labs(color = 'Median delay', size = '') +
    facet_grid(~ontime) +
    scale_colour_viridis(limits = c(-dlymax, dlymax), option="C") +
    scale_radius(range = c(0, 10))
 
stopdelays2 <- trip_updates %>%
    select(stop_id, timestamp, departure_delay) %>%
    filter(!is.na(departure_delay) & departure_delay > -60*60 & 
           departure_delay < 60 * 60) %>%
    collect() %>%
    mutate(stop_id = gsub("-.+", "", stop_id)) %>%
    inner_join(stops_tbl, by = "stop_id") %>%
    collect() %>%
    mutate(timestamp = as.POSIXct(timestamp, origin = '1970-01-01'),
           time = as.numeric(format(timestamp, '%H')) +
               as.numeric(format(timestamp, '%M')) / 60,
           peak = case_when(between(time, peak$morning[1], peak$morning[2]) ~ 'morning peak',
                            between(time, peak$evening[1], peak$evening[2]) ~ 'evening peak',
                            between(time, peak$morning[2], peak$evening[1]) ~ 'off peak',
                            TRUE ~ ''))

smrystops <- stopdelays2 %>%
    group_by(stop_id, peak) %>%
    summarize(delay = median(departure_delay, na.rm = TRUE),
              count = n(),
              stop_lon = mean(stop_lon),
              stop_lat = mean(stop_lat)) %>%
    arrange(abs(delay)) %>%
    ungroup() %>%
    mutate(peak = factor(peak, levels = c('morning peak', 'off peak', 'evening peak')),
           ontime = ifelse(delay >= 0, 'late', 'early'),
           ontime = factor(ontime, levels = c('late', 'early')))

dlymax <- max(abs(smrystops$delay/60))
ggmap(akl) +
    geom_point(aes(x = stop_lon, y = stop_lat, color = delay/60,
                   #size = abs(delay/60),
                   size = count),
               data = smrystops %>% filter(peak != '')) +
    labs(color = 'Median delay', size = '') +
    facet_grid(peak~ontime) +
    scale_colour_viridis(option = "C") + #limits = c(-dlymax, dlymax), option="C") +
    scale_radius(range = c(0, 8))
