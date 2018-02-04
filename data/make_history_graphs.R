library(tidyverse)
library(sugrrants)
library(magrittr)

#### READ IT ALL IN
files <- list.files('data/history', pattern = "*.csv", full.names = TRUE)
history <- read.csv(files[1])
for (file in files[-1]) history %<>% rbind(read.csv(file))

Nhistory <- history[, 2:6]
Qhistory <- history[, 7:12]
Times <- history[[1]]

Times <- as.POSIXct(Times, origin = "1970-01-01")
# Nhistory <- Nhistory[format(Times, "%Y") > 2000,]
# Qhistory <- Qhistory[format(Times, "%Y") > 2000,]
# Times <- Times[format(Times, "%Y") > 2000]


kk <- seq(1, nrow(Nhistory), by = 3)
datek <- as.factor(format(Times, "%Y-%m-%d"))


### calendar plot ...

Nhist <- as.data.frame(t(apply(cbind(0, Nhistory[kk, ]), 1, cumsum)))
# Nhist <- as.data.frame(t(apply(cbind(0, Nhistory[kk, ] / rowSums(Nhistory[kk, ])), 1, cumsum)))
colnames(Nhist) <- c("zero", "vearly", "early", "ontime", "late", "vlate")
Nhist %<>% 
    mutate(time = as.numeric(format(Times[kk], "%H")) + 
            as.numeric(format(Times[kk], "%M")) / 60) %>%
    mutate(date = as.Date(format(Times[kk], "%Y-%m-%d"))) %>%
    mutate(dummy = rep(c(0, max(Nhist$vlate)), length = nrow(.)))

Nhist.cal <- Nhist %>% 
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
legend1 <- tmp$grobs[[which(sapply(tmp$grobs, function(x) x$name) == "guide-box")]]

if (!interactive())
    jpeg("~/Dropbox/gtfs/figs/history_n.jpg", width = 1920, height = 1080)
gridExtra::grid.arrange(p1, legend1, ncol = 2, 
    widths = grid::unit.c(grid::unit(1, 'null'), sum(legend1$widths)))
if (!interactive())
    dev.off()

qmax <- 30
qmin <- -15
Qhist <- t(apply(Qhistory, 1, function(x) pmin(qmax, pmax(qmin, x))))
Qhist <- as.data.frame(cbind(0, Qhist[kk, ]))
colnames(Qhist) <- c("zero", "q5", "q125", "q25", "q75", "q875", "q95")
Qhist %<>% 
    mutate(time = as.numeric(format(Times[kk], "%H")) + 
            as.numeric(format(Times[kk], "%M")) / 60) %>%
    mutate(date = as.Date(format(Times[kk], "%Y-%m-%d"))) %>%
    mutate(weekend = ifelse(format(Times[kk], "%a") %in% c("Sat", "Sun"), "yes", "no")) %>%
    mutate(dummy = rep(c(qmin, qmax), length = nrow(.)))


Qhist.cal <- Qhist %>% 
    frame_calendar(x = time, y = vars(dummy, q5, q125, q25, q75, q875, q95, zero), 
                   date = date)
Qhist.week <- Qhist.cal %>% filter(weekend == "no")
Qhist.weekend <- Qhist.cal %>% filter(weekend == "yes")
zeroline <- with(Qhist.cal, tapply(.dummy, date, function(x) {
    a <- min(x)
    b <- max(x)
    -qmin / (qmax - qmin) * (b - a) + a
}))
Qhist.cal$.zero <- zeroline[as.character(Qhist.cal$date)]

## make an axis
rowRanges <- matrix(unique(Qhist.cal$.dummy), ncol = 2, byrow = TRUE)
q <- seq(-10, 20, by = 10)
rowAxes <- t(apply(rowRanges, 1, function(r) {
    a <- min(r)
    b <- max(r)
    (q - qmin) / (qmax - qmin) * (b - a) + a
}))
colnames(rowAxes) <- paste0('q', q)
Xmin <- min(Qhist.cal$.time)
Xat1 <- min(attr(Qhist.cal, 'minor_breaks')$x)
Xat0 <- Xat1 - (Xmin - Xat1)
rowAxes %<>% as.data.frame %>% 
    mutate(rown = 1:n()) %>%
    gather(key = 'tick', value = 'value', -rown) %>%
    mutate(label = gsub('q', '', tick),
           tickid = paste0(rown, tick),
           t0 = Xat0 - (Xmin - Xat1), t1 = Xat1)
axdata <- rbind(rowAxes %>% mutate(t = Xat0), 
                rowAxes %>% mutate(t = Xat1))

p <- ggplot(Qhist.cal, aes(x = .time, group = date)) +
    geom_ribbon(aes(ymin = .q5, ymax = .q95), data = Qhist.week, fill = "#bd9218") +
    geom_ribbon(aes(ymin = .q5, ymax = .q95), data = Qhist.weekend, fill = "#51a7f9") +
    geom_ribbon(aes(ymin = .q125, ymax = .q875), data = Qhist.week, fill = "#914507") +
    geom_ribbon(aes(ymin = .q125, ymax = .q875), data = Qhist.weekend, fill = "#2c7aaa") +
    geom_ribbon(aes(ymin = .q25, ymax = .q75), fill = "black") +
    geom_line(aes(y = .zero), colour = "#eeeeee") +
    geom_path(aes(x = t, y = value, group = tickid), data = axdata) +
    geom_path(aes(x = t1, y = value, group = rown), data = rowAxes) +
    geom_text(aes(x = t0, y = value, label = label, group = NULL), 
              data = rowAxes, hjust = 'right', size = 2.5)

p2 <- prettify(p, label.padding = unit(0.08, "lines"), label = c("label", "text", "text2"))

pleg <- ggplot(data.frame(x = factor(1:3, labels = c('90% of buses', '75% of buses', '50% of buses'))),
               aes(x = x, fill = x)) +
    geom_bar() + labs(fill = "") +
    scale_fill_manual(values=c("#bd9218", "#51a7f9", "black"))
tmp <- ggplot_gtable(ggplot_build(pleg))
legend2 <- tmp$grobs[[which(sapply(tmp$grobs, function(x) x$name) == "guide-box")]]

if (!interactive())
    jpeg("~/Dropbox/gtfs/figs/history_q.jpg", width = 1920, height = 1080)
gridExtra::grid.arrange(p2, legend2, ncol = 2, 
    widths = grid::unit.c(grid::unit(1, 'null'), sum(legend2$widths)))
if (!interactive())
    dev.off()


# gridExtra::grid.arrange(p1, legend1, p2, legend2, ncol = 2, nrow = 2,
#     widths = grid::unit.c(grid::unit(1, 'null'), sum(legend$widths)))