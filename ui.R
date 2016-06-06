
library(shiny)

shinyUI(pageWithSidebar(
        headerPanel("United States Relative Populations and Changes"),
        sidebarPanel(
                sliderInput('year', 'Pick a Year',min=2011, max=2015, value=2011, step=1, sep="", animate=TRUE),
                h2(""),
                p("These maps visualize the relative populations of the United States between 2011 and 2015."),
                p("The top map illustrates the relative population with darker states having higher populations."),
                p("The bottom map shows states that gained population in the preceding year in darker green, and shows lost population in a shade of red."),
                p("The sequence can be animated by pressing the small right arrow on the right side of the slider above."),
                a(href="http://www.census.gov/popest/data/national/totals/2015/","Based on data from the United States Census Bureau")
        ),
        mainPanel(
                plotOutput('map', width="100%")
        )
))
