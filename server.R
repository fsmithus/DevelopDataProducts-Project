
# Initialize application and load code.
library(maps)
library(mapproj)
library(maptools)

# Define function that draws the choropleth maps.
drawGraphics <- function(states,pop,delta) {
        
        # Note: Since all of the input data for this application is read-only (a mapping from a value to a color),
        # most of this function could be performed one time, during server initialization, to improve interactive
        # performance. But since performance does not seem to be an issue, I did not bother to optimize the code.
        # As is, the source data is scrubbed into a master data frame (i.e., census.data), and the colors are
        # recomputed with each interaction of the slider.
        
        # Initialize plot region.
        par(mfrow=c(2,1))
        par(mar=c(0,0,0,0))
        
        # White/blue palette for actual population.
        nc <- 100
        
        map.data <- data.frame(state=states,
                               value=pop,
                               colorIndex=integer(length(pop)), # saved for debugging purposes
                               color=character(length(pop)),
                               stringsAsFactors=FALSE)
        colors <- colorRampPalette(c("white","darkblue"))(nc)   # single linear palette of colors
        slope <- nc / max(map.data$value)                       # colors per population
        for (i in 1:length(map.data$value)) {                   # Calculate the color for each population value
                map.data$colorIndex[i] <- round(map.data$value[i] * slope)
                if (map.data$colorIndex[i] == 0) map.data$colorIndex[i] <- 1
                map.data$color[i] <- colors[map.data$colorIndex[i]]
        }
        
        # Draw the map using the maps package. match.map() matches map polygons to data records by state name.
        map("state",regions=census.data$state,exact=FALSE,proj="polyconic",fill=TRUE,
            col=map.data$color[match.map("state",regions=census.data$state,exact=FALSE,warn=TRUE)])
        
        
        # Red/white/green palette for changes in population.
        nc <- 50        # One half the number of colors.
        map.data <- data.frame(states,
                               value=delta,
                               colorIndex=integer(length(delta)),       # saved for debugging purposes
                               color=character(length(delta)),
                               stringsAsFactors=FALSE)
        inc.colors <- colorRampPalette(c("white","darkgreen"))(nc)      # two-sided linear palette for decrease/increase
        inc.slope = abs(nc / max(map.data$value))                       # colors per increasing population
        dec.colors <- colorRampPalette(c("white","darkred"))(nc)
        dec.slope = abs(nc / min(map.data$value))                       # colors per decreasing population
        
        for (i in 1:length(map.data$value)) {                           # Calculate the color for each population value
                if (map.data$value[i] < 0) {
                        map.data$colorIndex[i] <- round(abs(map.data$value[i] * dec.slope))
                        if (map.data$colorIndex[i] == 0) map.data$colorIndex[i] <- 1
                        map.data$color[i] <- dec.colors[map.data$colorIndex[i]]
                }
                else {
                        map.data$colorIndex[i] <- round(abs(map.data$value[i] * inc.slope))
                        if (map.data$colorIndex[i] == 0) map.data$colorIndex[i] <- 1
                        map.data$color[i] <- inc.colors[map.data$colorIndex[i]]
                }
        }
        
        # Draw the map using the maps package. match.map() matches map polygons to data records by state name.
        map("state",regions=census.data$state,exact=FALSE,proj="polyconic",fill=TRUE,
            col=map.data$color[match.map("state",regions=census.data$state,exact=FALSE,warn=TRUE)])
}


# Initialize read-only data.
# Download and load US 2015 census data.
if (!file.exists("NST-EST2015-alldata.csv")) {
        download.file("http://www.census.gov/popest/data/national/totals/2015/files/NST-EST2015-alldata.csv",
                      "NST-EST2015-alldata.csv")
}
census.data <- read.csv("NST-EST2015-alldata.csv")

# Remove all but state-level summaries
census.data <- census.data[census.data$SUMLEV==40,]

# Remove non-lower48 states (i.e., Puerto Rico, Alaska, and Hawaii)
census.data <- census.data[census.data$STATE!=2,]
census.data <- census.data[census.data$STATE!=15,]
census.data <- census.data[census.data$STATE!=72,]

# Reduce columns
census.data <- data.frame(state=tolower(census.data[,"NAME"]),
                          pop2010=census.data[,"POPESTIMATE2010"],
                          pop2011=census.data[,"POPESTIMATE2011"],
                          pop2012=census.data[,"POPESTIMATE2012"],
                          pop2013=census.data[,"POPESTIMATE2013"],
                          pop2014=census.data[,"POPESTIMATE2014"],
                          pop2015=census.data[,"POPESTIMATE2015"],
                          delta2011=census.data[,"POPESTIMATE2011"] - census.data[,"POPESTIMATE2010"],
                          delta2012=census.data[,"POPESTIMATE2012"] - census.data[,"POPESTIMATE2011"],
                          delta2013=census.data[,"POPESTIMATE2013"] - census.data[,"POPESTIMATE2012"],
                          delta2014=census.data[,"POPESTIMATE2014"] - census.data[,"POPESTIMATE2013"],
                          delta2015=census.data[,"POPESTIMATE2015"] - census.data[,"POPESTIMATE2014"],
                          stringsAsFactors=F)


# Define the server.
shinyServer(
        function(input,output) {
                # Initiallize a user session
                
                output$map <- renderPlot({
                        # Run when a widget value is changed.
                        drawGraphics(census.data$state,
                                     census.data[,paste0("pop",toString(input$year))],
                                     census.data[,paste0("delta",toString(input$year))])
                }, height=800, width=1200)
        }       
)