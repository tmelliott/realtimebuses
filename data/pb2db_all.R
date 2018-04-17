source("data/pb2db.R")
library(parallel)

cl <- makeCluster(6)
res <- clusterEvalQ(cl, {
    source('data/pb2db.R')
})
rm(res)

DATES <- seq(as.Date("2017-04-01"),
             as.Date("2018-04-01") - 1,
             by = 1)
dir.create("tmp")
pblapply(DATES, function(DATE) {
    dir <- sprintf("tmp/%s", DATE)
    dir.create(dir)
    o <- capture.output(system(
        sprintf('scp tom@130.216.51.230:/mnt/storage/history/%s/trip_updates_*.pb %s',
                gsub('-', '/', DATE, fixed = TRUE),
                dir)
    ))
    rm(o)
    files <- list.files(dir)
    DB <- sprintf("data/history_%s.db", DATE)
    ## pboptions(type = 'timer')
    invisible(sapply(files, pb2db, db = DB))
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
}, cl = cl)

stopCluster(cl)
