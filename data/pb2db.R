## Move protobuf (.pb) files to a database (.db)
if (dir.exists("../data")) setwd("..")
library(RCurl)
library(RSQLite)
library(RProtoBuf)
library(tidyverse)
library(pbapply)
readProtoFiles(dir = 'assets/protobuf')

pb2db <- function(file, db = 'data/history.db') {
    con <- try(dbConnect(SQLite(), db), silent = TRUE)
    if (inherits(con, "try-error")) return(1)
    on.exit({
        dbDisconnect(con)
    }, add = TRUE)
    
    pb <- try(read(transit_realtime.FeedMessage, file)$entity, silent = TRUE)
    if (inherits(pb, "try-error")) return(1)
    if (grepl("trip_updates", file)) {
        delays <- try(do.call(bind_rows, lapply(pb, function(x) {
            tu <- x$trip_update
            if (length(tu$stop_time_update) == 0) return(NULL)
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
                   
        })), silent = TRUE)
        if (inherits(delays, "try-error")) return(1)
        z <- try(dbWriteTable(con, 'tmp', delays, append = TRUE), silent = TRUE)
        if (inherits(z, "try-error")) return(1)
    } else {
        
    }

    invisible(0)
}



