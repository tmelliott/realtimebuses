today <- Sys.Date()
start.date <- format(today, "%Y-%m-01")

fillPage(fillCol(
    headerPanel("Auckland Transport Bus Delays"),

    mainPanel(
        flowLayout(
            dateRangeInput(
                "dates", "Choose a range of dates to view",
                start = start.date, end = today,
                min = "2017-03-13", max = today,
                startview = "year",
                format = "dd M yyyy"
            ),

            radioButtons(
                "type", "Plot type", list(`Number` = "n", `Quantiles` = "q")
            ),

            radioButtons(
                "caltype", "View calendar in", list("months" = "monthly", "weeks" = "weekly")
            )
        ),

        width = 12
    ),

    plotOutput("hist", height = "100%"),

    flex = c(NA, NA, 1)
))
