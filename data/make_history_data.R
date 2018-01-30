## Generate a whole bunch of historical data 
## for the past 5 weeks, and display the info in graphs
#
# Needed (at every 5-minutes)
#  - Number of buses,
#  - delay distribution, N (10+ min early; 5-10 min early; on-time; 5-10 min late; 10+ min late)
#  - quantiles of delay [5%, 25%, 75%, 95%]

library(RProtoBuf)
readProtoFiles(dir = 'assets/protobuf')

DATE <- Sys.Date()
DOW <- as.numeric(format(DATE, "%w"))

## want to get Monday of this week
MON <- DATE - ifelse(DOW == 0, 6, DOW - 1)
BEGIN <- MON - 4 * 7
END <- DATE
DATES <- as.Date(BEGIN:END, origin = "1970-01-01")

#DATES <- DATES[1:3]

con <- "tom@130.216.51.230"
Nhistory <- matrix(0L, ncol = 5, nrow = (24 - 5) * (60 / 5) * length(DATES))
Qhistory <- matrix(0.0, ncol = 6, nrow = (24 - 5) * (60 / 5) * length(DATES))
Times <- vector('integer', nrow(Nhistory))
prog <- txtProgressBar(0, nrow(Nhistory), style = 3)
for (i in seq_along(DATES)) {
    day <- DATES[i]
    dir <- file.path("/mnt", "storage", "history",
                     format(day, "%Y"),
                     format(day, "%m"),
                     format(day, "%d"))
    ## only need the trip_updates files, for every 5 minute interval
    times <- seq(as.POSIXct(paste(day, "5:00:00")),
                 as.POSIXct(paste(day, "23:55:00")), by = 5 * 60)
    for (j in seq_along(times)) {
        k <- (i-1) * length(times) + j
        setTxtProgressBar(prog, k)
        t <- times[j]
        if (t > Sys.time()) break
        filename <- sprintf("trip_updates_%s%s%s%s%s*.pb",
                            format(day, "%Y"),
                            format(day, "%m"),
                            format(day, "%d"),
                            format(t, "%H"), 
                            format(t, "%M"))
        file <- system(sprintf("ssh %s ls %s", con, file.path(dir, filename)), intern = TRUE)
        if (length(file) == 0) next
        file <- file[1]
        # fc <- 
        pb <- read(transit_realtime.FeedMessage, pipe(sprintf("ssh %s cat %s", con, file)))$entity
        # close(fc)

        delays <- sapply(pb, function(x) {
            ifelse(x$trip_update$stop_time_update[[1]]$has('arrival'),
                   x$trip_update$stop_time_update[[1]]$arrival$delay,
                   x$trip_update$stop_time_update[[1]]$departure$delay)
        })
        
        Nt <- integer(5)
        Nt[1] <- sum(delays < -10 * 60)
        Nt[2] <- sum(delays >= -10 * 60 & delays < -5 * 60)
        Nt[3] <- sum(delays >= -5 * 60 & delays < 5 * 60)
        Nt[4] <- sum(delays >= 5 * 60 & delays < 10 * 60)
        Nt[5] <- sum(delays >= 10 * 60)
        Nhistory[k, ] <- Nt
        Qhistory[k, ] <- quantile(delays, c(0.05, 0.125, 0.25, 0.75, 0.875, 0.95)) / 60
        Times[k] <- as.integer(t)
    }
}
close(prog)

## Write each into its own file ...


dput(list(Nhistory, Qhistory, Times), "bushistory.Rdump")


XL <- dget("bushistory.Rdump")
Nhistory <- XL[[1]]
Qhistory <- XL[[2]]
Times <- XL[[3]]
rm(XL)

Times <- as.POSIXct(Times, origin = "1970-01-01")
Nhistory <- Nhistory[format(Times, "%Y") > 2000,]
Qhistory <- Qhistory[format(Times, "%Y") > 2000,]
Times <- Times[format(Times, "%Y") > 2000]

library(tidyverse)

kk <- seq(1, nrow(Nhistory), by = 3)
datek <- as.factor(format(Times, "%Y-%m-%d"))

# plist <- tapply(kk, datek[kk], function(k) {
#     Nsum <- t(apply(Nhistory[k, ], 1, cumsum))
#     ggplot(NULL, aes(x = Times[k])) + 
#         geom_area(aes(y = Nsum[, 5]), fill = "#bb0000") +
#         geom_area(aes(y = Nsum[, 4]), fill = "orange") +
#         geom_area(aes(y = Nsum[, 3]), fill = "green3") +
#         geom_area(aes(y = Nsum[, 2]), fill = "orange") +
#         geom_area(aes(y = Nsum[, 1]), fill = "#bb0000") +
#         xlab("") + ylab("") + 
#         xlim(as.POSIXct(paste(datek[k[1]], c("05:00:00", "24:00:00")),
#                         origin = "1970-01-01")) +
#         ylim(c(0, max(rowSums(Nhistory)))) +
#         theme(axis.text.x = element_blank())
# })
# plist$ncol <- 7
# plist$nrow <- 6
# plist <- c(list(), plist)
# do.call(gridExtra::grid.arrange, plist)


### calendar plot ...
library(sugrrants)
library(magrittr)

Nhist <- as.data.frame(t(apply(cbind(0, Nhistory[kk, ]), 1, cumsum)))
# Nhist <- as.data.frame(t(apply(cbind(0, Nhistory[kk, ] / rowSums(Nhistory[kk, ])), 1, cumsum)))
colnames(Nhist) <- c("zero", "vearly", "early", "ontime", "late", "vlate")
Nhist %<>% 
    mutate(time = as.numeric(format(Times[kk], "%H")) + 
            as.numeric(format(Times[kk], "%M")) / 60) %>%
    mutate(date = as.Date(format(Times[kk], "%Y-%m-%d"))) %>%
    mutate(dummy = rep(c(0, max(Nhist$vlate)), length = nrow(.)))

Nhist.cal <- Nhist %>% 
    filter(date >= '2018-01-01') %>%
    frame_calendar(x = time, y = vars(dummy, vlate, zero, vearly, early, ontime, late), 
                   date = date)
p <- ggplot(Nhist.cal, aes(x = .time, ymin = .zero, group = date)) +
    geom_ribbon(aes(ymax = .vlate), fill = "#bb0000") +
    geom_ribbon(aes(ymax = .late), fill = "orange") +
    geom_ribbon(aes(ymax = .ontime), fill = "green3") +
    geom_ribbon(aes(ymax = .early), fill = "orange") +
    geom_ribbon(aes(ymax = .vearly), fill = "#bb0000")
p1 <- prettify(p, label.padding = unit(0.08, "lines"), label = c("label", "text", "text2"))

pleg <- ggplot(data.frame(x = factor(1:5, labels = c('10+ min late', '5-10 min late', 'ontime',
                                       '5-10 min early', '10+ min early'))),
               aes(x = x, fill = x)) +
    geom_bar() + labs(fill = "") +
    scale_fill_manual(values=c("#bb0000", "orange", "green3", "orange", "#bb0000"))
tmp <- ggplot_gtable(ggplot_build(pleg))
legend <- tmp$grobs[[which(sapply(tmp$grobs, function(x) x$name) == "guide-box")]]

gridExtra::grid.arrange(p1, legend, ncol = 2, 
    widths = grid::unit.c(grid::unit(1, 'null'), sum(legend$widths)))


Qhistory <- t(apply(Qhistory, 1, function(x) pmin(30, pmax(-10, x))))
Qhist <- as.data.frame(cbind(0, Qhistory[kk, ]))
colnames(Qhist) <- c("zero", "q5", "q125", "q25", "q75", "q875", "q95")
Qhist %<>% 
    mutate(time = as.numeric(format(Times[kk], "%H")) + 
            as.numeric(format(Times[kk], "%M")) / 60) %>%
    mutate(date = as.Date(format(Times[kk], "%Y-%m-%d"))) %>%
    mutate(weekend = ifelse(format(Times[kk], "%a") %in% c("Sat", "Sun"), "yes", "no")) %>%
    mutate(dummy = rep(c(-10, 30), length = nrow(.)))


Qhist.cal <- Qhist %>% 
    filter(date >= '2018-01-01') %>%
    frame_calendar(x = time, y = vars(dummy, q5, q125, q25, q75, q875, q95, zero), 
                   date = date)
Qhist.week <- Qhist.cal %>% filter(weekend == "no")
Qhist.weekend <- Qhist.cal %>% filter(weekend == "yes")
p <- ggplot(Qhist.cal, aes(x = .time, group = date)) +
    geom_ribbon(aes(ymin = .q5, ymax = .q95), data = Qhist.week, fill = "#bd9218") +
    geom_ribbon(aes(ymin = .q5, ymax = .q95), data = Qhist.weekend, fill = "#51a7f9") +
    geom_ribbon(aes(ymin = .q125, ymax = .q875), data = Qhist.week, fill = "#914507") +
    geom_ribbon(aes(ymin = .q125, ymax = .q875), data = Qhist.weekend, fill = "#2c7aaa") +
    geom_ribbon(aes(ymin = .q25, ymax = .q75), fill = "black")

p1 <- prettify(p, label.padding = unit(0.08, "lines"), label = c("label", "text", "text2"))
p1