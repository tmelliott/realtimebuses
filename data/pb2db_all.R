source("data/pb2db.R")
library(parallel)

cl <- makeCluster(6)
res <- clusterEvalQ(cl, {
    source('data/pb2db.R')
})
rm(res)

## create tmp dir for all of the files
if (!dir.exists("tmp")) {
    unlink("tmp")
}
dir.create("tmp")

## only deal with dates that haven't been done yet ...
DATES <- seq(as.Date("2017-04-01"),
             as.Date("2018-04-01") - 1,
             by = 1)
DATES <- DATES[sapply(DATES, function(date) 
                !file.exists(sprintf("data/history_%s.db", date)))]
res <- pblapply(DATES, function(DATE) {
    dir <- sprintf("tmp/%s", DATE)
    dir.create(dir)

    o <- try(capture.output(system(
            sprintf('scp tom@130.216.51.230:/mnt/storage/history/%s/trip_updates_*.pb %s',
                    gsub('-', '/', DATE, fixed = TRUE),
                    dir)
        )), silent = TRUE)
    if (inherits(o, "try-error")) {
        unlink(dir)
        return(1)
    }
    rm(o)
    files <- list.files(dir, full.names = TRUE)
    DB <- sprintf("data/history_%s_unfinished.db", DATE)
    ## pboptions(type = 'timer')
    z <- sapply(files, pb2db, db = DB)
    if (any(z == 1)) warning("Not all files could be processed")
    rm(z)
    unlink(dir, TRUE, TRUE)
    rm(files)
    ## copy to main table, removing duplicates in the process
    con <- dbConnect(SQLite(), DB)
    tbl <- dbReadTable(con, 'tmp')
    dbRemoveTable(con, 'tmp')
    tbl <- tbl[tapply(1:nrow(tbl),
                      with(tbl, paste(vehicle_id, timestamp)),
                      function(i) i[1]), ]
    dbWriteTable(con, 'trip_updates', tbl, append = TRUE)
    dbDisconnect(con)
    ## rename file to 
    file.rename(DB, gsub("_unfinished", "", DB, fixed = TRUE))
    return(0)
}, cl = cl)

stopCluster(cl)
unlink("tmp")

cat("The following dates didn't process:\n")
print(DATES[sapply(res, function(x) x == 1)])
