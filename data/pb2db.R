## Move protobuf (.pb) files to a database (.db)
library(RCurl)
library(RSQLite)
library(RProtoBuf)
readProtoFiles(dir = 'assets/protobuf')

pb2db <- function(file, db = 'history.db') {
    newdb <- !file.exists('history.db')
    con <- dbConnect(SQLite(), db)
    
    pb <- read(transit_realtime.FeedMessage, file)$entity
    if (grepl("trip_updates", file)) {
        
    } else {
        
    }

tmp <- tempfile()
system(
    sprintf('scp tom@130.216.51.230:/mnt/storage/history/2018/04/02/archive_2018_04_02.zip %s', tmp)
)
files <- unzip(tmp, exdir = tempdir())
unlink(tmp)

for (file in files) {
    pb2db(file)
}
