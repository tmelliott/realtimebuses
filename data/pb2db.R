## Move protobuf (.pb) files to a database (.db)
library(RCurl)
library(RSQLite)
library(RProtoBuf)
library(tidyverse)
readProtoFiles(dir = 'assets/protobuf')

pb2db <- function(file, db = 'data/history.db') {
    con <- dbConnect(SQLite(), db)
    
    pb <- read(transit_realtime.FeedMessage, file)$entity
    if (grepl("trip_updates", file)) {
        delays <- do.call(bind_rows, lapply(pb, function(x) {
            tu <- x$trip_update
            stu <- tu$stop_time_update[[1]]
            tibble(vehicle_id = tu$vehicle$id,
                   timestamp = as.integer(tu$timestamp),
                   trip_id = tu$trip$trip_id,
                   route_id = tu$trip$route_id,
                   stop_sequence = as.integer(stu$stop_sequence),
                   stop_id = stu$stop_id,
                   arrival_delay = ifelse(stu$has('arrival'),
                                          stu$arrival$delay, NA),
                   departure_delay = ifelse(stu$has('departure'),
                                            stu$departure$delay, NA))
                   
        })) 
        dbWriteTable(con, 'tmp', delays, append = TRUE)
    } else {
        
    }
    dbDisconnect(con)
    invisible(0)
}

DATE <- commandArgs(TRUE)[1]

tmp <- tempfile()
system(
    sprintf('scp tom@130.216.51.230:/mnt/storage/history/%s/archive_%s.zip %s',
            gsub('-', '/', DATE, fixed = TRUE), gsub('-', '_', DATE, fixed = TRUE), tmp)
)
files <- unzip(tmp, exdir = tempdir())
unlink(tmp)

#unlink('data/history.db')
invisible(pbapply::pbsapply(files, pb2db))

## copy to main table, removing duplicates in the process
con <- dbConnect(SQLite(), "data/history.db")
tbl <- dbReadTable(con, 'tmp')
dbRemoveTable(con, 'tmp')
tbl <- tbl[tapply(1:nrow(tbl),
                  with(tbl, paste(vehicle_id, timestamp)),
                  function(i) i[1]), ]
dbWriteTable(con, 'trip_updates', tbl, append = TRUE)
dbDisconnect(con)
