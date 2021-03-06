## vim:textwidth=128:expandtab:shiftwidth=4:softtabstop=4


##cacheAge <- 5                          # a global variable
col <- list(core=7, bgc=3, deep=6)

## Start and end times, covering 21 days to usually get 2 cycles
endTime <- as.POSIXlt(Sys.time())
startTime <- as.POSIXlt(endTime - 10 * 86400)


#' @importFrom grDevices grey
#' @importFrom graphics arrows image lines mtext
uiMapApp <- shiny::fluidPage(
                             shiny::headerPanel(title="", windowTitle="argoFloats mapApp"),
                             shiny::tags$script('$(document).on("keypress", function (e) { Shiny.onInputChange("keypress", e.which); Shiny.onInputChange("keypressTrigger", Math.random()); });'),
                             style="text-indent:1em; background:#e6f3ff ; .btn.disabled { background-color: red; }",
                             shiny::fluidRow(shiny::column(4,
                                                           shiny::p("mapApp"), style="color:blue;"),
                                             shiny::column(1,
                                                           shiny::actionButton("help", "Help")),
                                             shiny::column(1,
                                                           shiny::actionButton("code", "Code")),
                                             shiny::column(4,
                                                           style="margin-top: 0px;",
                                                           shiny::actionButton("goW", shiny::HTML("&larr;")),
                                                           shiny::actionButton("goN", shiny::HTML("&uarr;")),
                                                           shiny::actionButton("goS", shiny::HTML("&darr;")),
                                                           shiny::actionButton("goE", shiny::HTML("&rarr;")),
                                                           shiny::actionButton("zoomIn", "+"),
                                                           shiny::actionButton("zoomOut", "-"))),
                             shiny::fluidRow(shiny::column(2,
                                                           shiny::textInput("start",
                                                                            "Start",
                                                                            value=sprintf("%4d-%02d-%02d",
                                                                                          startTime$year + 1900,
                                                                                          startTime$mon + 1,
                                                                                          startTime$mday))),
                                             shiny::column(2,
                                                           shiny::textInput("end",
                                                                            "End",
                                                                            value=sprintf( "%4d-%02d-%02d",
                                                                                          endTime$year + 1900,
                                                                                          endTime$mon + 1, endTime$mday))),
                                             shiny::column(6,
                                                           style="padding-left:0px;",
                                                           shiny::checkboxGroupInput("view",
                                                                                     label="View",
                                                                                     choices=c("Core"="core", "Deep"="deep",
                                                                                               "BGC"="bgc", "HiRes"="hires",
                                                                                               "Topo."="topo", "Path"="path", "Start"="start", "End"="end"),
                                                                                     selected=c("core", "deep", "bgc"),
                                                                                     inline=TRUE))),
                             shiny::fluidRow(shiny::column(2,
                                                           shiny::textInput("ID", "Float ID", value="")),
                                             shiny::column(2,
                                                           style="padding-left:0px;",
                                                           shiny::selectInput("focus",
                                                                              "Focus",
                                                                              choices=c("All"="all", "Single"="single"),
                                                                              selected="all")),
                                             shiny::column(8,
                                                           shiny::verbatimTextOutput("info"))),
                             ## using withSpinner does not work here
                             shiny::fluidRow(shiny::plotOutput("plotMap",
                                                               hover=shiny::hoverOpts("hover"),
                                                               dblclick=shiny::dblclickOpts("dblclick"),
                                                               brush=shiny::brushOpts("brush", delay=2000, resetOnNew=TRUE))))

## @importFrom shiny actionButton brushOpts checkboxGroupInput column dblclickOpts fluidPage fluidRow headerPanel HTML p plotOutput selectInput showNotification tags textInput
serverMapApp <- function(input, output, session) {
    age <- shiny::getShinyOption("age")
    destdir <- shiny::getShinyOption("destdir")
    argoServer <- shiny::getShinyOption("argoServer")
    debug <- shiny::getShinyOption("debug")
    if (!requireNamespace("shiny", quietly=TRUE))
        stop("must install.packages('shiny') for mapApp() to work")
    ## State variable: reactive!
    state <- shiny::reactiveValues(xlim=c(-180, 180),
                                   ylim=c(-90, 90),
                                   startTime=startTime,
                                   endTime=endTime,
                                   focusID=NULL)
    ## Depending on whether 'hires' selected, 'coastline' wil be one of the following two version:
    data("coastlineWorld", package="oce", envir=environment())
    coastlineWorld <- get("coastlineWorld")
    data("coastlineWorldFine", package="ocedata", envir=environment())
    coastlineWorldFine <- get("coastlineWorldFine")
    ## Depending on whether 'hires' selected, 'topo' wil be one of the following two version:
    data("topoWorld", package="oce", envir=environment())
    topoWorld <- get("topoWorld")
    if (file.exists("topoWorldFine.rda")) {
        load("topoWorldFine.rda")
    } else {
        topoWorldFine <- topoWorld
    }
    ## Get core and bgc data.
    notificationId <- shiny::showNotification("Getting \"core\" argo index, either by downloading new data or using cached data.  This may take a minute or two.", type="message", duration=NULL)
    i <- argoFloats::getIndex(age=age, destdir=destdir, server=argoServer, debug=debug)
    shiny::removeNotification(notificationId)
    notificationId <- shiny::showNotification("Getting \"bgc\" argo index, either by downloading new data or using cached data.  This may take a minute or two.", type="message", duration=NULL)
    iBGC <- argoFloats::getIndex("bgc", age=age, destdir=destdir, server=argoServer, debug=debug)
    shiny::removeNotification(notificationId)
    ## Combine core and bgc data.
    notificationId <- shiny::showNotification("Combining \"core\" and \"bgc\" data.", type="message", duration=NULL)
    ID <- i[["ID"]]
    cycle <- i[["cycle"]]
    lon <- i[["longitude"]]
    lat <- i[["latitude"]]
    idBGC <- unique(iBGC[["ID"]])
    n <- length(ID)
    type <- rep("core", n)
    type[ID %in% idBGC] <- "bgc"
    type[grepl("849|862|864", i@data$index$profiler_type)] <- "deep"
    argo <- data.frame(time=i[["date"]], ID=ID, cycle=cycle, longitude=lon, latitude=lat, type=type)
    argo$longitude <- ifelse(argo$longitude > 180, argo$longitude - 360, argo$longitude)
    ok <- is.finite(argo$time)
    argo <- argo[ok, ]
    ok <- is.finite(argo$longitude)
    argo <- argo[ok, ]
    ok <- is.finite(argo$latitude)
    argo <- argo[ok, ]
    visible <- rep(TRUE, length(argo$lon)) # vector indicating whether to keep any given cycle.
    shiny::removeNotification(notificationId)

    ## Functions used to prevent off-world points
    pinlat <- function(lat)
        ifelse(lat < -90, -90, ifelse(90 < lat, 90, lat))
    pinlon <- function(lon)
        ifelse(lon < -180, -180, ifelse(180 < lon, 180, lon))
    ## Function to show an error instead of a plot
    showError <- function(msg)
    {
        plot(0:1, 0:1, xlab="", ylab="", type="n", axes=FALSE)
        text(0.5, 0.5, msg, col=2, font=2)
    }

    output$info <- shiny::renderText({
        ## show location.  If lat range is under 90deg, also show nearest float within 100km
        x <- input$hover$x
        y <- input$hover$y
        lonstring <- ifelse(x < 0, sprintf("%.2fW", abs(x)), sprintf("%.2fE", x))
        latstring <- ifelse(y < 0, sprintf("%.2fS", abs(y)), sprintf("%.2fN", y))
        if (diff(range(state$ylim)) < 90 && sum(visible)) {
            fac <- 1 / cos(y * pi / 180) ^ 2 # for deltaLon^2 compared with deltaLat^2
            dist2 <- ifelse(visible, fac * (x - argo$longitude) ^ 2 + (y - argo$latitude) ^ 2, 1000)
            i <- which.min(dist2)
            dist <- sqrt(dist2[i]) * 111 # 1deg lat approx 111km
            if (length(dist) && dist < 100) {
                sprintf("%s %s, %.0f km from %s float with ID %s\n  at cycle %s [%s]",
                        lonstring,
                        latstring,
                        dist,
                        switch(argo$type[i], "core"="Core", "bgc"="BGC", "deep"="Deep"),
                        argo$ID[i],
                        argo$cycle[i],
                        format(argo$time[i], "%Y-%m-%d %H:%M"))
            } else {
                sprintf("%s %s", lonstring, latstring)
            }
        } else {
            sprintf("%s %s", lonstring, latstring)
        }
    })

    shiny::observeEvent(input$goE,
                        {
                            dx <- diff(state$xlim) # present longitude span
                            state$xlim <<-
                                pinlat(state$xlim + dx / 4)
                        })

    shiny::observeEvent(input$goW,
                        {
                            dx <- diff(state$xlim) # present longitude span
                            state$xlim <<-
                                pinlat(state$xlim - dx / 4)
                        })

    shiny::observeEvent(input$goS,
                        {
                            dy <- diff(state$ylim) # present latitude span
                            state$ylim <<-
                                pinlat(state$ylim - dy / 4)
                        })

    shiny::observeEvent(input$goN,
                        {
                            dy <- diff(state$ylim) # present latitude span
                            state$ylim <<-
                                pinlat(state$ylim + dy / 4)
                        })

    shiny::observeEvent(input$zoomIn,
                        {
                            state$xlim <<-
                                pinlon(mean(state$xlim)) + c(-0.5, 0.5) / 1.3 * diff(state$xlim)
                            state$ylim <<-
                                pinlat(mean(state$ylim)) + c(-0.5, 0.5) / 1.3 * diff(state$ylim)
                        })

    shiny::observeEvent(input$zoomOut,
                        {
                            state$xlim <<-
                                pinlon(mean(state$xlim) + c(-0.5, 0.5) * 1.3 * diff(state$xlim))
                            state$ylim <<-
                                pinlat(mean(state$ylim) + c(-0.5, 0.5) * 1.3 * diff(state$ylim))
                        })

    shiny::observeEvent(input$code,
                        {
                            msg <- "library(argoFloats)<br>"
                            msg <- paste(msg, "# Download (or use cached) index from one of two international servers.<br>")
                            msg <- paste(msg, "index <- getIndex()<br>")
                            msg <- paste(msg, "# Subset by time.<br>")
                            msg <- paste(msg, "from <- as.POSIXct(\"", format(state$startTime, "%Y-%m-%d"), "\", tz=\"UTC\")<br>", sep="")
                            msg <- paste(msg, "to <- as.POSIXct(\"", format(state$endTime, "%Y-%m-%d"), "\", tz=\"UTC\")<br>", sep="")
                            msg <- paste(msg, "subset1 <- subset(index, time=list(from=from, to=to))<br>")
                            msg <- paste(msg, "# Subset by space.<br>", sep="")
                            lonRect <- state$xlim
                            latRect <- state$ylim
                            msg <- paste(msg, sprintf("rect <- list(longitude=c(%.4f,%.4f), latitude=c(%.4f,%.4f))<br>",
                                                      lonRect[1], lonRect[2], latRect[1], latRect[2]))
                            msg <- paste(msg, "subset2 <- subset(subset1, rectangle=rect)<br>")
                            msg <- paste(msg, "# Plot a map (with different formatting than used here).<br>")
                            msg <- paste(msg, "plot(subset2, which=\"map\")<br>")
                            msg <- paste(msg, "# The following shows how to make a TS plot for these profiles. This<br>")
                            msg <- paste(msg, "# involves downloading, which will be slow for a large number of<br>")
                            msg <- paste(msg, "# profiles, so the steps are placed in an unexecuted block.<br>")
                            msg <- paste(msg, "if (FALSE) {<br>")
                            msg <- paste(msg, "&nbsp;&nbsp; profiles <- getProfiles(subset2)<br>")
                            msg <- paste(msg, "&nbsp;&nbsp; argos <- readProfiles(profiles)<br>")
                            msg <- paste( msg, "&nbsp;&nbsp; plot(applyQC(argos), which=\"TS\", TScontrol=list(colByCycle=1:8))<br>")
                            msg <- paste(msg, "}<br>")
                            shiny::showModal(shiny::modalDialog(shiny::HTML(msg), title="R code", size="l"))
                        })

    shiny::observeEvent(input$ID,
                        {
                            if (0 == nchar(input$ID)) {
                                state$focusID <<- NULL
                                shiny::updateTextInput(session, "focus", value="all")
                            } else {
                                k <- which(argo$ID == input$ID)
                                if (length(k)) {
                                    state$focusID <<- input$ID
                                    state$xlim <<- pinlon(extendrange(argo$lon[k], f = 0.15))
                                    state$ylim <<- pinlat(extendrange(argo$lat[k], f = 0.15))
                                    if (input$focus == "all")
                                        shiny::showNotification(paste0("Since you entered a float ID (", input$ID, "), you might want to change Focus to \"Single\""),
                                                                type="message", duration=10
                                        )
                                } else {
                                    shiny::showNotification(paste0("There is no float with ID ", input$ID, "."), type="error")
                                }
                            }
                        })

    shiny::observeEvent(input$focus,
                        {
                            if (input$focus == "single") {
                                if (is.null(state$focusID)) {
                                    shiny::showNotification(
                                        "Double-click on a point or type an ID in the 'Flost ID' box, to single out a focus float",
                                        type = "error",
                                        duration = NULL
                                    )
                                } else {
                                    k <- argo$ID == state$focusID
                                    ## Extend the range 3X more than the default, because I almost always
                                    ## end up typing "-" a few times to zoom out
                                    state$xlim <<- pinlon(extendrange(argo$lon[k], f = 0.15))
                                    state$ylim <<- pinlat(extendrange(argo$lat[k], f = 0.15))
                                    ## Note: extending time range to avoid problems with day transitions,
                                    ## which can might cause missing cycles at the start and end; see
                                    ## https://github.com/ArgoCanada/argoFloats/issues/283.
                                    state$startTime <<- min(argo$time[k]) - 86400
                                    state$endTime <<- max(argo$time[k]) + 86400
                                    shiny::updateTextInput(session, "start", value=format(state$startTime, "%Y-%m-%d"))
                                    shiny::updateTextInput(session, "end", value=format(state$endTime, "%Y-%m-%d"))
                                }
                            } else {
                                # "all"
                                shiny::updateTextInput(session, "ID", value="")
                                state$focusID <<- NULL
                            }
                        })

    shiny::observeEvent(input$dblclick,
                        {
                            x <- input$dblclick$x
                            y <- input$dblclick$y
                            fac <- 1 / cos(y * pi / 180) ^ 2 # for deltaLon^2 compared with deltaLat^2
                            if (input$focus == "single" && !is.null(state$focusID)) {
                                keep <- argo$ID == state$focusID
                            } else {
                                ## Restrict search to the present time window
                                keep <- state$startTime <= argo$time & argo$time <= state$endTime
                            }
                            i <- which.min(ifelse( keep, fac * (x - argo$longitude) ^ 2 + (y - argo$latitude)^2, 1000))
                            state$focusID <<- argo$ID[i]
                            shiny::updateTextInput(session, "ID", value=state$focusID)
                            msg <- sprintf("ID %s, cycle %s<br>%s %.3fE %.3fN",
                                           argo$ID[i],
                                           argo$cycle[i],
                                           format(argo$time[i], "%Y-%m-%d"),
                                           argo$longitude[i],
                                           argo$latitude[i])
                            shiny::showNotification(shiny::HTML(msg), duration=NULL)
                        })

    shiny::observeEvent(input$start,
                        {
                            if (0 == nchar(input$start)) {
                                state$startTime <<- min(argo$time, na.rm=TRUE)
                            } else {
                                t <- try(as.POSIXct(input$start, tz="UTC"), silent=TRUE)
                                if (inherits(t, "try-error")) {
                                    shiny::showNotification(paste0("Start time \"",
                                                                   input$start,
                                                                   "\" is not in yyyy-mm-dd format, or is otherwise invalid."), type="error")
                                } else {
                                    state$startTime <<- t
                                }
                            }
                        })

    shiny::observeEvent(input$end,
                        {
                            if (0 == nchar(input$end)) {
                                state$endTime <<- max(argo$time, na.rm = TRUE)
                            } else {
                                t <- try(as.POSIXct(input$end, tz = "UTC"), silent = TRUE)
                                if (inherits(t, "try-error")) {
                                    shiny::showNotification(paste0( "End time \"", input$end, "\" is not in yyyy-mm-dd format, or is otherwise invalid."), type = "error")
                                } else {
                                    state$endTime <<- t
                                }
                            }
                        })

    shiny::observeEvent(input$help,
                        {
                            msg <- "Enter values in the Start and End boxes to set the time range in numeric yyyy-mm-dd format, or empty either box to use the full time range of the data.<br><br>Use 'View' to select profiles to show (core points are in yellow, deep in purple, and bgc in green), whether to show coastline and topography in high or low resolution, whether to show topography, and whether to connect points to indicate float paths. <br><br>Click-drag the mouse to enlarge a region. Double-click on a particular point to get a popup window giving info on that profile. After such double-clicking, you may change to focus to Single, to see the whole history of that float's trajectory.<br><br>A box above the plot shows the mouse position in longitude and latitude.  If the latitude range is under 90 degrees, and the mouse is within 100km of a float location, that box will also show the float ID and the cycle (profile) number.<br><br>The \"R code\" button brings up a window showing R code that isolates to the view shown and demonstrates some further operations.<br><br>Type '?' to bring up a window that lists key-stroke commands, for further actions including zooming and shifting the spatial view, and sliding the time window.<br><br>For more details, type <tt>?argoFloats::mapApp</tt> in an R console."
                            shiny::showModal(shiny::modalDialog(shiny::HTML(msg), title="Using this application", size="l"))
                        })                                  # help

    shiny::observeEvent(input$keypressTrigger,
                        {
                            key <- intToUtf8(input$keypress)
                            if (key == "n") {
                                dy <- diff(state$ylim) # present latitude span
                                state$ylim <<- pinlat(state$ylim + dy / 4)
                            } else if (key == "s") {
                                dy <- diff(state$ylim) # present latitude span
                                state$ylim <<- pinlat(state$ylim - dy / 4)
                            } else if (key == "e") {
                                dx <- diff(state$xlim) # present latitude span
                                state$xlim <<- pinlon(state$xlim + dx / 4)
                            } else if (key == "w") {
                                dx <- diff(state$xlim) # present latitude span
                                state$xlim <<- pinlon(state$xlim - dx / 4)
                            } else if (key == "f") {
                                # forward in time
                                interval <- as.numeric(state$endTime) - as.numeric(state$startTime)
                                state$startTime <<- state$startTime + interval
                                state$endTime <<- state$endTime + interval
                                shiny::updateTextInput(session, "start", value=format(state$startTime, "%Y-%m-%d"))
                                shiny::updateTextInput(session, "end", value=format(state$endTime, "%Y-%m-%d"))
                            } else if (key == "b") {
                                # backward in time
                                interval <- as.numeric(state$endTime) - as.numeric(state$startTime)
                                state$startTime <<- state$startTime - interval
                                state$endTime <<- state$endTime - interval
                                shiny::updateTextInput(session, "start", value=format(state$startTime, "%Y-%m-%d"))
                                shiny::updateTextInput(session, "end", value=format(state$endTime, "%Y-%m-%d"))
                            } else if (key == "i") {
                                # zoom in
                                state$xlim <<- pinlon(mean(state$xlim)) + c(-0.5, 0.5) / 1.3 * diff(state$xlim)
                                state$ylim <<- pinlat(mean(state$ylim)) + c(-0.5, 0.5) / 1.3 * diff(state$ylim)
                            } else if (key == "o") {
                                state$xlim <<- pinlon(mean(state$xlim) + c(-0.5, 0.5) * 1.3 * diff(state$xlim))
                                state$ylim <<- pinlat(mean(state$ylim) + c(-0.5, 0.5) * 1.3 * diff(state$ylim))
                            } else if (key == "r") {
                                # reset to start
                                state$xlim <<- c(-180, 180)
                                state$ylim <<- c(-90, 90)
                                state$startTime <<- startTime
                                state$endTime <<- endTime
                                state$focusID <<- NULL
                                shiny::updateSelectInput(session, "focus", selected="all")
                                shiny::updateCheckboxGroupInput(session, "show", selected=character(0))
                            } else if (key == "?") {
                                shiny::showModal(shiny::modalDialog(title="Key-stroke commands",
                                                                    shiny::HTML("<ul> <li> '<b>i</b>': zoom <b>i</b>n</li>
                                                                                <li> '<b>o</b>': zoom <b>o</b>ut</li>
                                                                                <li> '<b>n</b>': go <b>n</b>orth</li>
                                                                                <li> '<b>e</b>': go <b>e</b>ast</li>
                                                                                <li> '<b>s</b>': go <b>s</b>outh</li>
                                                                                <li> '<b>w</b>': go <b>w</b>est</li>
                                                                                <li> '<b>f</b>': go <b>f</b>orward in time</li>
                                                                                <li> '<b>b</b>': go <b>b</b>ackward in time </li>
                                                                                <li> '<b>r</b>': <b>r</b>eset to initial state</li>
                                                                                <li> '<b>?</b>': display this message</li> </ul>"), easyClose=TRUE))
                            }
                        })                                  # keypressTrigger

    output$plotMap <- shiny::renderPlot({
        start <- state$startTime
        end <- state$endTime
        if (start > end) {
            showError(paste0("Start must precede End , but got Start=", format(start, "%Y-%m-%d"), " and End=", format(end, "%Y-%m-%d.")))
        } else {
            if (!is.null(input$brush)) {
                ## Require a minimum size, to avoid mixups with minor click-slide
                if ((input$brush$xmax - input$brush$xmin) > 0.5 && (input$brush$ymax - input$brush$ymin) > 0.5) {
                    state$xlim <<- c(input$brush$xmin, input$brush$xmax)
                    state$ylim <<- c(input$brush$ymin, input$brush$ymax)
                }
            }
            if (0 == sum(c("core", "deep", "bgc") %in% input$view)) {
                showError("Please select at least 1 type")
            } else {
                par(mar = c(2.5, 2.5, 2, 1.5))
                plot(state$xlim, state$ylim, xlab="", ylab="", axes=FALSE, type="n", asp=1 / cos(pi / 180 * mean(state$ylim)))
                topo <- if ("hires" %in% input$view) topoWorldFine else topoWorld
                if ("topo" %in% input$view) {
                    image(topo[["longitude"]], topo[["latitude"]], topo[["z"]], add=TRUE, breaks=seq(-8000, 0, 100), col=oce::oceColorsGebco(80))
                }
                usr <- par("usr")
                usr[1] <- pinlon(usr[1])
                usr[2] <- pinlon(usr[2])
                usr[3] <- pinlat(usr[3])
                usr[4] <- pinlat(usr[4])
                at <- pretty(usr[1:2], 10)
                at <- at[usr[1] < at & at < usr[2]]
                labels <- paste(abs(at), ifelse(at < 0, "W", ifelse(at > 0, "E", "")), sep="")
                axis(1, pos=pinlat(usr[3]), at=at, labels=labels, lwd=1)
                at <- pretty(usr[3:4], 10)
                at <- at[usr[3] < at & at < usr[4]]
                labels <- paste(abs(at), ifelse(at < 0, "S", ifelse(at > 0, "N", "")), sep="")
                axis(2, pos=pinlon(usr[1]), at=at, labels=labels, lwd=1)
                coastline <- if ("hires" %in% input$view) coastlineWorldFine else coastlineWorld
                polygon(coastline[["longitude"]], coastline[["latitude"]], col="tan")
                rect(usr[1], usr[3], usr[2], usr[4], lwd = 1)
                ## For focusID mode, we do not trim by time or space
                if (input$focus == "single" && !is.null(state$focusID)) {
                    keep <- argo$ID == state$focusID
                }  else {
                    keep <- rep(TRUE, length(argo$ID))
                }
                keep <- keep & (state$startTime <= argo$time & argo$time <= state$endTime)
                keep <- keep & (state$xlim[1] <= argo$longitude & argo$longitude <= state$xlim[2])
                keep <- keep & (state$ylim[1] <= argo$latitude & argo$latitude <= state$ylim[2])
                cex <- 0.75
                ## Draw points, optionally connecting paths (and indicating start points)
                ## {{{
                visible <<- rep(FALSE, length(argo$lon))
                for (view in c("core", "deep", "bgc")) {
                    if (view %in% input$view) {
                        k <- keep & argo$type == view
                        visible <<- visible | k
                        lonlat <- argo[k,]
                        points(lonlat$lon, lonlat$lat, pch=21, cex=cex, col="black", bg=col[[view]], lwd=0.5)
                        if ("path" %in% input$view) {
                            ##> ## Turn off warnings for zero-length arrows
                            ##> owarn <- options("warn")$warn
                            ##> options(warn = -1)
                            for (ID in unique(lonlat$ID)) {
                                LONLAT <- lonlat[lonlat$ID==ID,]
                                ##cat(file=stderr(), sprintf("ID=%s, n=%d, nsub=%d\n", ID, dim(lonlat)[1], dim(LONLAT)[1]))
                                ## Sort by time instead of relying on the order in the repository
                                o <- order(LONLAT$time)
                                no <- length(o)
                                if (no > 1) {
                                    LONLAT <- LONLAT[o, ]
                                    lines(LONLAT$lon, LONLAT$lat, lwd=1, col=grey(0.3))
                                    ##> arrows(
                                    ##>     LONLAT$lon[no - 1],
                                    ##>     LONLAT$lat[no - 1],
                                    ##>     LONLAT$lon[no],
                                    ##>     LONLAT$lat[no],
                                    ##>     length = 0.15,
                                    ##>     lwd = 1.4
                                    ##> )
                                    ## Point size increases for > 10 locations (e.g. a many-point trajectory for a single float,
                                    ## as opposed to maybe 3 months of data for a set of floats).
                                    if ("start" %in% input$view)
                                        points(LONLAT$lon[1], LONLAT$lat[1], pch=2, cex=if (no > 10) 2 else 1, lwd=1.4)
                                    if ("end" %in% input$view)
                                        points(LONLAT$lon[no], LONLAT$lat[no], pch=0, cex=if (no > 10) 2 else 1, lwd=1.4)
                                }
                            }
                            ##> par(warn = owarn)
                        }
                    }
                }
                ## }}}
                ## Draw the inspection rectangle as a thick gray line, but only if zoomed
                if (-180 < state$xlim[1] || state$xlim[2] < 180 || -90 < state$ylim[1] || state$ylim[2] < 90)
                    rect(state$xlim[1], state$ylim[1], state$xlim[2], state$ylim[2], border="darkgray", lwd=4)
                ## Write a margin comment
                if (input$focus == "single" &&
                    !is.null(state$focusID)) {
                    mtext(paste("Float ID", state$focusID), cex=0.8 * par("cex"), line=0.25)
                } else {
                    mtext(side=3, sprintf( "%s to %s: %d Argo profiles", format(start, "%Y-%m-%d"), format(end, "%Y-%m-%d"), sum(visible)), line=0.25, cex=0.8 * par("cex"))
                }
            }
        }
    }, height=500, pointsize=18)       # plotMap
}                                      # serverMapApp

#' Interactive app for viewing Argo float positions
#'
#' The GUI permits specifying a spatial-temporal region of interest, a set
#' of float types to show, etc.  The interface ought to be reasonably
#' straightforward, especially for those who take a moment to click on the
#' Help button and to read the popup window that it creates.
#'
#' This app will use [getIndex()] to download index files from the Argo server
#' the first time it runs, and this make take up to a minute or so.  Then it will combine
#' information from the core-Argo and bgc-Argo index tables, cross-indexing so
#' it can determine the Argo type for each profile (or cycle).
#'
#' The `hi-res` button will only affect the coastline, not the topography,
#' unless there is a local file named `topoWorldFine.rda` that contains
#' an alternative topographic information. Here is how to create such a file:
#'```R
#' library(oce)
#' topoFile <- download.topo(west=-180, east=180,
#'                           south=-90, north=90,
#'                           resolution=10,
#'                           format="netcdf", destdir=".")
#' topoWorldFine <- read.topo(topoFile)
#' save(topoWorldFine, file="topoWorldFine.rda")
#' unlink(topoFile) # clean up
#'```
#'
#' @param age numeric value indicating how old a downloaded file
#' must be (in days), for it to be considered out-of-date.  The
#' default, [argoDefaultIndexAge()], limits downloads to once per day, as a way
#' to avoid slowing down a workflow with a download that might take
#' a minute or so. Note that setting `age=0` will force a new
#' download, regardless of the age of the local file.
#'
#' @template destdir
#'
#' @param server character value, or vector of character values, indicating the name of
#' servers that supply argo data acquired with [getIndex()].  The default value,
#' `"auto"`, indicates to try a sequence of servers.
#'
#' @param debug integer value that controls how much information `mapApp()` prints
#' to the console as it works.  The default value of 0 leads to a fairly limited
#' amount of printing, while higher values lead to more information. This information
#' can be helpful in diagnosing problems or bottlenecks.
#'
#' @examples
#'\dontrun{
#' library(argoFloats)
#' mapApp()}
#'
#' @author Dan Kelley
#' @importFrom shiny shinyApp shinyOptions
#' @export
mapApp <- function(age=argoDefaultIndexAge(), destdir=argoDefaultDestdir(), server="auto", debug=0)
{
    debug <- as.integer(max(0, min(debug, 3))) # put in range from 0 to 3
    shiny::shinyOptions(age=age, destdir=destdir, argoServer=server, debug=debug) # rename server to avoid shiny problem
    if (!requireNamespace("shiny", quietly=TRUE))
        stop("must install.packages(\"shiny\") for this to work")
    print(shiny::shinyApp(ui=uiMapApp, server=serverMapApp))
}

#shiny::shinyApp(ui, server)
