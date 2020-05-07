## vim:textwidth=128:expandtab:shiftwidth=4:softtabstop=4

#' Download and Cache a Dataset
#'
#' General function for downloading and caching a dataset.
#'
#' @template url
#' @template destdir
#' @template destfile
#' @template mode
#' @template quiet
#' @template force
#' @template retries
#' @template debug
#'
#' @return String indicating the full pathname to the downloaded file.
#' @importFrom utils unzip
#' @importFrom curl curl_download
#' @export
#' @author Dan Kelley
downloadWithRetries <- function(url, destdir="~/data/argo", destfile=NULL, mode="wb", quiet=FALSE,
                                force=FALSE, retries=3, debug=0)
{
    if (missing(url))
        stop("must specify url")
    if (length(destdir) > 1)
        stop("destdir must be of length 1")
    retries <- max(1, as.integer(retries))
    argoFloatsDebug(debug, "downloadWithRetries(\n",
                    style="bold", sep="", unindent=1)
    argoFloatsDebug(debug, "    url='", paste(url, collapse="', '"), "',\n",
                    style="bold", sep="", unindent=1)
    argoFloatsDebug(debug, "    destdir='", destdir, "',\n",
                    style="bold", sep="", unindent=1)
    argoFloatsDebug(debug, "    destfile='", paste(destfile, collapse="', '"), "',\n",
                    style="bold", sep="", unindent=1)
    argoFloatsDebug(debug, "    mode='", mode, "'", ", quiet=", quiet, ", force=", force, ",\n",
                    style="bold", sep="", unindent=1)
    argoFloatsDebug(debug, "    retries=", retries, ") {\n",
                    style="bold", sep="", unindent=1)
    n <- length(url)
    if (length(destfile) != n)
        stop("length(url)=", n, " must equal length(destfile)=", length(destfile))
    for (i in 1:n) {
        destination <- paste0(destdir, "/", destfile[i])
        if (!force && file.exists(destination)) {
            argoFloatsDebug(debug, "Skipping \"", destination, "\" because it already exists\n", sep="")
        } else {
            success <- FALSE
            for (trial in seq_len(1 + retries)) {
                t <- try(curl::curl_download(url=url, destfile=destination, quiet=quiet, mode=mode))
                if (!inherits(t, "try-error")) {
                    success <- TRUE
                    break
                }
            }
            if (!success)
                stop("failed to download from '", url, "', after ", retries, " retries")
            if (1 == length(grep(".zip$", destfile[i]))) {
                destinationClean <- gsub(".zip$", "", destination[i])
                unzip(destination[i], exdir=destinationClean)
                destination[i] <- destinationClean
                argoFloatsDebug(debug, "  Downloaded and unzipped into '", destination[i], "'\n", sep="")
            } else {
                argoFloatsDebug(debug, "  Downloaded file stored as '", destination[i], "'\n", sep="")
            }
        }
    }
    argoFloatsDebug(debug, "} # downloadWithRetries()\n", style="bold", unindent=1)
    destination
}
