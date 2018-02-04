## Generate a whole bunch of historical data 
## for the past 5 weeks, and display the info in graphs
#
# Needed (at every 5-minutes)
#  - Number of buses,
#  - delay distribution, N (10+ min early; 5-10 min early; on-time; 5-10 min late; 10+ min late)
#  - quantiles of delay [5%, 25%, 75%, 95%]

library(RProtoBuf)
readProtoFiles(dir = 'assets/protobuf')

dothedata <- function(DATES) {
    DATES <- DATES[sapply(DATES, function(x) !any(grepl(x, list.files('data/history'))))]
    if (length(DATES) == 0) return()
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
            pb <- read(transit_realtime.FeedMessage, pipe(sprintf("ssh %s cat %s", con, file)))$entity

            delays <- sapply(pb, function(x) {
                if (x$has('trip_update')) {
                    tus <- x$trip_update$stop_time_update
                    if (length(tus) == 1) {
                        tu <- tus[[1]]
                        if (tu$has('arrival'))
                            if (tu$arrival$has('delay')) return(tu$arrival$delay)
                        if (tu$has('departure'))
                            if (tu$departure$has('delay')) return (tu$departure$delay)
                    }
                }
                return(NA)
            })
            delays <- delays[!is.na(delays)]
            
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
    cat("\n## Writing each into its own file ...\n\n")
    dir <- './data/history'
    Times <- as.POSIXct(Times, origin = "1970-01-01")
    invisible(tapply(seq_along(Times), 
        as.factor(format(Times, "%Y-%m-%d")), 
        function(k) {
            res <- cbind(as.integer(Times[k]), Nhistory[k, ], round(Qhistory[k, ], 2))
            colnames(res) <- 
                c("time", "veryearly", "early", "ontime", "late", "verylate",
                  "q0.05", "q0.125", "q0.25", "q0.75", "q0.875", "q0.9")
            write.csv(res,
                sprintf("%s/history_%s.csv", dir, format(Times[k[1]], "%Y-%m-%d")),
                quote = FALSE, row.names = FALSE)
        }))
    unlink('data/history/history_1970-01-01.csv')
}

# XL <- dget("bushistory.Rdump")
# Nhistory <- XL[[1]]
# Qhistory <- XL[[2]]
# Times <- XL[[3]]
# rm(XL)


# DATE <- Sys.Date()
# DOW <- as.numeric(format(DATE, "%w"))

# ## want to get Monday of this week
# MON <- DATE - ifelse(DOW == 0, 6, DOW - 1)
# BEGIN <- MON - 4 * 7
# END <- DATE - 1
# DATES <- as.Date(BEGIN:END, origin = "1970-01-01")
# DATES <- DATES[sapply(DATES, function(x) !any(grepl(x, list.files('data/history'))))]


for (i in 9:10) {
    START <- as.Date(sprintf("2017-%02d-01", i), origin = "1970-01-01")
    END <- as.Date(sprintf("2017-%02d-01", i+1), origin = "1970-01-01") - 1
    DATES <- as.Date(START:END, origin = "1970-01-01")
    dothedata(DATES)
}
