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
BEGIN <- MON - 5 * 7
END <- DATE
DATES <- as.Date(BEGIN:END, origin = "1970-01-01")

#DATES <- DATES[1:3]

con <- "tom@130.216.51.230"
Nhistory <- matrix(0L, ncol = 5, nrow = (24 - 5) * (60 / 5) * length(DATES))
Qhistory <- matrix(0.0, ncol = 4, nrow = (24 - 5) * (60 / 5) * length(DATES))
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
        Qhistory[k, ] <- quantile(delays, c(0.05, 0.25, 0.75, 0.95)) / 60
        Times[k] <- as.integer(t)
    }
}
close(prog)

dput(list(Nhistory, Qhistory, Times), "bushistory.Rdump")

library(tidyverse)

Times <- as.POSIXct(Times, origin = "1970-01-01")
kk <- seq(1, nrow(Nhistory), by = 3)
datek <- as.factor(format(Times[kk], "%Y-%m-%d"))

plist <- tapply(kk, datek, function(k) {
    Nsum <- t(apply(Nhistory[k, ], 1, cumsum))
    ggplot(NULL, aes(x = Times[k])) + 
        geom_area(aes(y = Nsum[, 5]), fill = "#bb0000") +
        geom_area(aes(y = Nsum[, 4]), fill = "orange") +
        geom_area(aes(y = Nsum[, 3]), fill = "green3") +
        geom_area(aes(y = Nsum[, 2]), fill = "orange") +
        geom_area(aes(y = Nsum[, 1]), fill = "#bb0000") +
        xlab("") + ylab("") + ylim(c(0, max(rowSums(Nhistory)))) +
        theme(axis.text.x = element_blank())
})
plist$ncol <- 7
plist$nrow <- 6
do.call(gridExtra::grid.arrange, plist)