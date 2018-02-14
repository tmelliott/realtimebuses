con <- url("https://dl.dropboxusercontent.com/s/cemi1ctf7wzbj3k/delayhistory.rda?dl=1")
load(con)
close(con)

.MINDATE <- as.Date("2017-03-13")
.MAXDATE <- max(Nhist$date)
