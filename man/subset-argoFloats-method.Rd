% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/subset.R
\name{subset,argoFloats-method}
\alias{subset,argoFloats-method}
\title{Subset an argoFloats Object}
\usage{
\S4method{subset}{argoFloats}(x, subset = NULL, ...)
}
\arguments{
\item{x}{an \code{\linkS4class{argoFloats}} object as created by \code{\link[=getIndex]{getIndex()}}.}

\item{subset}{optional numerical or logical vector that indicates which
indices of \code{x@data$index} to keep (example 1).}

\item{...}{the first entry here must be either (a) a list named \code{circle},
\code{rectangle}, \code{polygon}, \code{parameter}, \code{time}, \code{institution},
\code{ID},\code{ocean},\code{dataMode},\code{cycle}, \code{direction}, or \code{column}.
(examples 2 through 8, and 10 through 14),
or (b) a logical value named \code{deep} (example 9).  Optionally, this entry
may be followed by second entry named \code{silent}, which is a logical
value indicating whether to prevent the printing of messages that
indicate the number (and percentage) of data that are kept
during the subsetting operation.
See \dQuote{Details} and \dQuote{Examples}.}
}
\value{
An \code{\linkS4class{argoFloats}} object.
}
\description{
Return a subset of an \code{\linkS4class{argoFloats}} for two object types:
A) type \code{"index"}, as created by \code{\link[=getIndex]{getIndex()}}, either by specifying indices
to keep (using the \code{subset} argument) or by specifying a way to determine
those indices (using the \code{...} argument). Note that only one subset condition
may be given in the \code{...} argument, but that \code{\link[=merge,argoFloats-method]{merge,argoFloats-method()}} can
be used to merge indices  created by \code{subset}, which effectively creates a
logical "or" operation.
B) type \code{"argos"}, as created by \code{\link[=readProfiles]{readProfiles()}}. Note that the only subset
condition that can be give in the \code{...} argument is \code{column},\code{cycle}, or
\code{dataStateIndicator} for \code{argos} type.
}
\details{
The possibilities for the \code{...} argument are as follows.
\enumerate{
\item An integer vector giving indices to keep. See example 1.
\item A list named \code{circle} with numeric elements named \code{longitude},
\code{latitude} and \code{radius}.  The first two give the center of
the subset region, and the third gives the radius of
that region, in kilometers. See example 2.
\item A list named \code{rectangle}, which has elements named
\code{longitude} and \code{latitude}, two-element numeric vectors
giving the western and eastern, and southern and northern
limits of the selection region. See example 3.
\item A list named \code{polygon} that has elements named \code{longitude} and \code{latitude}
that are numeric vectors specifying a polygon within which profiles
will be retained. The polygon must not be self-intersecting,
and an error message will be issued if it is.  If the polygon is not closed
(i.e. if the first and last points do not coincide) the first point is pasted
onto the end, to close it.
See example 4.
\item A vector or list named \code{parameter} that holds character values that
specify the names of measured parameters to keep. See section 3.3 of the
Argo User's Manual, V3.3 (Carval et al. 2019) for a list of parameters.
See example 5.
\item A list named \code{time} that has elements \code{from} and \code{to} that are either
POSIXt times, or character strings that \code{subset()} will convert to
POSIXt times using \code{\link[=as.POSIXct]{as.POSIXct()}} with \code{tz="UTC"}. See example 6.
\item A list named \code{institution}, which holds a single character element that
names the institution.  The permitted values are:
\code{"AO"} for AOML, USA;
\code{"BO"} for BODC, United Kingdom;
\code{"CS"} for CSIRO, Australia;
\code{"HZ"} for CSIO, China Second Institute of Oceanography;
\code{"IF"} for Ifremer, France;
\code{"IN"} for INCOIS, India;
\code{"JA"} for JMA, Japan;
\code{"KM"} for KMA, Korea;
\code{"KO"} for KORDI, Korea;
\code{"ME"} for MEDS, Canada; and
\code{"NM"} for NMDIS, China.
See example 7.
\item A list named \code{deep} that holds a logical value indicating weather argo floats
are deep argo (i.e. \code{profiler_type} 849, 862, and 864). See example 8.
\item A list named \code{ID} that holds a character value specifying a float identifier.
See example 9.
\item A list named \code{ocean}, which holds a single character element that names the
ocean. The permitted values are:
\code{"A"} for Atlantic Ocean Area, from 70 W to 20 E,
\code{"P"} for Pacific Ocean Area, from 145 E to 70 W, and
\code{"I"} for Indian Ocean Area, from 20 E to 145 E.
See example 10.
\item A character value named \code{dataMode}, equal to either \code{realtime} or \code{delayed},
that selects whether to retain real-time data or delayed data.
See example 11.
\item An integer value named \code{cycle} that specifies which cycles are to be retained.
This is done by regular-expression matching of the filename, looking between the
underline character (\code{"_"}) and the suffix (\code{.nc}), but note that the expression
is made up of a compulsory component comprising 3 or 4 digits, and an optional
component that is either blank or the character \code{"D"} (which designates a
descending profile).  Thus, \code{001} will match both \verb{*_001.nc} and \verb{*_001D.nc}.
Note this can be used for both \code{"index"} and \code{"argos"} types.
See example 12.
\item A character value named \code{direction}, equal to either "descent" or "ascent",
that selects whether to retain data from the ascent or decent phase.
See example 13.
\item An integer value named \code{column}, that selects which column of parameters
to obtain. Note that this type of subset is possible for \code{argos} and \code{index}
type objects.
See example 14.
\item A integer value named \code{debug} that controls whether \code{subset()} prints
some information to describe what it is doing.
\item A character value named \code{dataStateIndicator}, equal to either "0A", "1A",
"2B", "2B+", "2C", "2C+", "3B", or "3C", that selects which \code{dataStateIndicator}
to keep.  See table 6 of the Argo User's Manual, V3.3 (Carval et al. 2019) to
understand the processing stage of data.
See example 16.
}

In all cases, the notation is that longitude is positive
for degrees East and negative for degrees West, and that latitude
is positive for degrees North and negative for degrees South.
}
\examples{
library(argoFloats)
data(index)

# Example 1: subset to the first 3 profiles in the (built-in) index
index1 <- subset(index, 1:3)
cat("First 3 longitudes:", paste(index1[["longitude"]]), "\n")

# Example 2: subset to a circle near Abaca Island
index2 <- subset(index, circle=list(longitude=-77.5, latitude=27.5, radius=50))

# Example 3: subset to a rectangle near Abaca Island
lonRect <- c(-76.5, -76)
latRect <- c(26.5, 27.5)
index3 <- subset(index, rectangle=list(longitude=lonRect, latitude=latRect))

# Example 4: subset to a polygon to near Abaco Island
poly <- list(longitude=c(-77.492, -78.219, -77.904, -77.213, -76.728, -77.492),
             latitude=c(26.244, 25.247, 24.749, 24.987, 25.421, 26.244))
index4 <- subset(index, polygon=poly)

# Show some of these subsets on a map
plot(index, bathymetry=FALSE)
points(index2[["longitude"]], index2[["latitude"]], col=2, pch=20, cex=1.4)
points(index3[["longitude"]], index3[["latitude"]], col=3, pch=20, cex=1.4)
rect(lonRect[1], latRect[1], lonRect[2], latRect[2], border=3, lwd=2)
points(index4[["longitude"]], index4[["latitude"]], col=4, pch=20, cex=1.4)
polygon(poly$longitude, poly$latitude, border=4)

# Example 5: subset synthetic data containing "DOXY" parameters
# Data containing "DOXY" data
data(indexSynthetic)
index5A <- subset(indexSynthetic, parameter="DOXY")
# Data containing both "PSAL" and "DOWN_IRRADIANCE380" data
data(indexSynthetic)
index5B <- subset(indexSynthetic, parameter=c("PSAL", "DOWN_IRRADIANCE380"))

# Example 6: subset data for the year 2019
data(index)
index6 <- subset(index, time=list(from="2019-01-01", to="2019-12-31"))

# Example 7: subset to the Canadian MEDS data
index7 <- subset(index, institution="ME")

# Example 8: subset to a specific ID
\dontrun{
ai <- getIndex(filename="synthetic")
index9 <- subset(ai, ID="1900722")}

# Example 9: subset data to only include deep argo
\dontrun{
ai <- getIndex(filename="synthetic")
index8 <- subset(ai, deep=TRUE)}

# Example 10: subset data by ocean
\dontrun{
ai <- getIndex()
index10 <- subset(ai, circle=list(longitude=-83, latitude=9, radius=500))
plot(index10, which="map")
atlantic <- subset(index10, ocean="A") # Subsetting for Atlantic Ocean
pacific <- subset(index10, ocean="P")
points(atlantic[["longitude"]], atlantic[["latitude"]], pch=20, col=2)
points(pacific[["longitude"]], pacific[["latitude"]], pch=20, col=3)}

# Example 11: subset by delayed time
\dontrun{
data(indexBgc)
index11 <- subset(indexBgc, dataMode="delayed")
profiles <- getProfiles(index11)
argos <- readProfiles(profiles)
oxygen <- argos[["oxygen"]][[3]]
pressure <- argos[["pressure"]][[3]]
plot(oxygen, pressure, ylim=rev(range(pressure, na.rm=TRUE)),
     ylab="Pressure (dbar)", xlab="Oxygen (umol/kg)")}

# Example 12: subset by cycle
\dontrun{
data(index)
index12 <- subset(index, cycle="124")
cat("File names with cycle number 124:", paste(index12[["file"]]), "\n")}

# Example 13: subset by direction
\dontrun{
library(argoFloats)
index13A <- subset(getIndex(), deep=TRUE)
index13B <- subset(index13A, direction="descent")
head(index13B[["file"]])}

# Example 14: subset by column (for argos type)
\dontrun{
library(argoFloats)
index14A <- subset(getIndex(filename="synthetic"), ID="5903889")
index14B <- subset(index14A, cycle="074")
argos14A <- readProfiles(getProfiles(index14B))
argos14B <- subset(argos14A, column=1)
D <- data.frame(Oxygen = argos14A[["oxygen"]],
col1= argos14B[["oxygen"]][[1]])}

# Example 15: subset by cycle (for argos type) to create TS diagram
\dontrun{
data("index")
index15 <- subset(index, ID="1901584")
profiles <- getProfiles(index15)
argos <- readProfiles(profiles)
plot(subset(argos, cycle="147"), which="TS")}

# Example 16: subset by dataStateIndicator
\dontrun{
data("index")
index16 <- subset(index, 1:40)
argos <- readProfiles(getProfiles(index16))
argos16A <- subset(argos, dataStateIndicator="2C")
argos16B <- subset(argos, dataStateIndicator="2B")}

}
\references{
Carval, Thierry, Bob Keeley, Yasushi Takatsuki, Takashi Yoshida, Stephen Loch Loch,
Claudia Schmid, and Roger Goldsmith. Argo User’s Manual V3.3. Ifremer, 2019.
\url{https://doi.org/10.13155/29825}.
}
\author{
Dan Kelley and Jaimie Harbin
}
