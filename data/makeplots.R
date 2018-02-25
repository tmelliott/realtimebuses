library(tidyverse)
library(lubridate)
library(sugrrants)
library(magrittr)



makePlots <- function(dates, which = c("n", "q"), calendar = c('monthly', 'weekly')) {
    which <- match.arg(which)
    calendar <- match.arg(calendar)

    switch(which, 
        "n" = {
            Nhist.cal <- Nhist %>% 
                filter(date >= dates[1] & date <= dates[2]) %>%
                frame_calendar(x = time, y = vars(dummy, vlate, zero, vearly, early, ontime, late), 
                               date = date, calendar = calendar)
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

            gridExtra::grid.arrange(p1, legend1, ncol = 2, 
                widths = grid::unit.c(grid::unit(1, 'null'), sum(legend1$widths)))
        },
        "q" = {
            qmax <- 30
            qmin <- -15
            Qhist.cal <- Qhist %>% 
                filter(date >= dates[1] & date <= dates[2]) %>%
                frame_calendar(x = time, y = vars(dummy, q5, q125, q25, q75, q875, q95, zero), 
                               date = date, calendar = calendar)
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

            gridExtra::grid.arrange(p2, legend2, ncol = 2, 
                widths = grid::unit.c(grid::unit(1, 'null'), sum(legend2$widths)))
        }
    )
}