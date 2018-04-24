library(pbapply)
pboptions(type="timer")

DB <- "history.db"
if (file.exists(DB))
    unlink(DB)

files <- list.files(pattern = "history_.*.db")

file.copy(files[1], DB)
system(sprintf("chmod 644 %s", DB))
x <- pblapply(files[-1], function(file) {
    system(sprintf(
        paste(sep="; ",
            "sqlite3 %s 'attach \"%s\" as db",
            "insert into trip_updates select * from db.trip_updates'"
        ), DB, file))
})

cat("Done\n")
