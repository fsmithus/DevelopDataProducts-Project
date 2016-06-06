
# Initialize application and load code.
library(maps)
library(mapproj)
library(maptools)

# Define function that draws the choropleth maps.
drawMaps <- function(states,pop,delta) {
        # Note: states is not used, but just passed in for debugging purposes.
        
        # Note: Since all of the input data for this application is read-only (a mapping from a value to a color),
        # most of this function could be performed one time, during server initialization, to improve interactive
        # performance. But since performance does not seem to be an issue, I did not bother to optimize the code.
        
        # Initialize plot region.
        par(mfrow=c(2,1))
        par(mar=c(0,0,0,0))
        
        # White/blue palette for actual population.
        nc <- 50
        
        map.data <- data.frame(state=states,
                               value=pop,
                               colorIndex=integer(length(pop)),
                               color=character(length(pop)),
                               stringsAsFactors=FALSE)
        colors <- colorRampPalette(c("white","darkblue"))(nc)
        slope <- nc / max(map.data$value)
        for (i in 1:length(map.data$value)) {
                map.data$colorIndex[i] <- round(map.data$value[i] * slope)
                if (map.data$colorIndex[i] == 0) map.data$colorIndex[i] <- 1
                map.data$color[i] <- colors[map.data$colorIndex[i]]
        }
        
        map("state",proj="polyconic",fill=TRUE,col=map.data$color)
        
        
        # Red/white/green palette for changes in population.
        nc <- 50        # One half the number of colors.
        map.data <- data.frame(states,
                               value=delta,
                               colorIndex=integer(length(delta)),
                               color=character(length(delta)),
                               stringsAsFactors=FALSE)
        inc.colors <- colorRampPalette(c("darkgreen","white"))(nc)
        inc.slope = abs(nc / max(map.data$value))
        dec.colors <- colorRampPalette(c("white","darkred"))(nc)
        dec.slope = abs(nc / min(map.data$value))
        
        for (i in 1:length(map.data$value)) {
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
        
        map("state",proj="polyconic",fill=TRUE,col=map.data$color)
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
                        drawMaps(census.data$state,
                                 census.data[,paste0("pop",toString(input$year))],
                                 census.data[,paste0("delta",toString(input$year))])
                }, height=800, width=1200)
        }       
)