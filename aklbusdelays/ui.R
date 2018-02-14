fillPage(fillCol(
    headerPanel("Auckland Transport Bus Delays"),

    mainPanel(wellPanel(
        flowLayout(

            radioButtons(
                "type", "Plot type", list(`Number` = "n", `Quantiles` = "q")
            ),

            radioButtons(
                "caltype", "View calendar in", list("months" = "monthly", "weeks (buggy)" = "weekly")
            ),

            selectInput(
                'datepresets', 'View how many months?',
                c(1, 2, 3, 6, 12)
            ),

            dateRangeInput(
                "dates", "Or choose a range of dates to view",
                start = format(.MAXDATE, "%Y-%m-01"), end = .MAXDATE,
                min = .MINDATE, max = .MAXDATE,
                startview = "year",
                format = "dd M yyyy"
            )
        )
    ), width = 12),

    plotOutput("hist", height = "100%"),

    flex = c(NA, NA, 1)
))
