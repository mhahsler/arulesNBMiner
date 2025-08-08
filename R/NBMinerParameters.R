#' Estimate Global Model Parameters from Data
#'
#' Estimate the global negative binomial data model used by the NBMiner and
#' create an appropriate parameter object.
#'
#' Uses the EM algorithm to estimate the global NB model for the data. The EM
#' algorithm is used since the zero class (items which do not occur in the
#' dataset) is not included in the data. The result are the two NB parameters
#' \eqn{k} and \eqn{a}, where \eqn{a} is rescaled by dividing it by the number
#' of incidences in the data (this is needed by the NBMiner). Also the real
#' number of items \eqn{n} is a result of the estimation.
#'
#' \code{theta} and \code{pi} are just taken and added to the resulting
#' parameter object.
#'
#' @param data the data as a object of class [arules::transactions].
#' @param trim fraction of incidences to trim off the tail of the frequency
#' distribution of the data.
#' @param pi precision threshold \eqn{\pi}.
#' @param theta pruning parameter \eqn{\theta}.
#' @param minlen minimum number of items in found itemsets (default: 1).
#' @param maxlen maximal number of items in found itemsets (default: 5).
#' @param rules mine NB-precise rules instead of NB-frequent itemsets?
#' @param plot plot the model?
#' @param verbose use verbose output for the estimation procedure.
#' @param getdata get also the observed and estimated counts.
#' @return an object of class `"NBMinerParameter"`` to be used for [NBMiner()].
#' @references Michael Hahsler. A model-based frequency constraint for mining
#' associations from transaction data. \emph{Data Mining and Knowledge
#' Discovery,13(2):137-166,} September 2006.
#' \doi{10.1007/s10618-005-0026-2}
#' @keywords models
#' @examples
#' data("Epub")
#'
#' param <- NBMinerParameters(Epub, trim = 0.05, plot = TRUE, verbose = TRUE)
#' param
#'
NBMinerParameters <- function(data,
                              trim = 0.01,
                              pi = 0.99,
                              theta = 0.5,
                              minlen = 1,
                              maxlen = 5,
                              rules = FALSE,
                              plot = FALSE,
                              verbose = FALSE,
                              getdata = FALSE) {
  itemf <- itemFrequency(data, type = "abs")

  ## the number of items with 0 occurrences is unobservable
  obs <- c(0, tabulate(itemf))
  r <- .estim_nbinom(obs,
                     trim = trim,
                     missing_zeros = TRUE,
                     verb = verbose)

  k <- r$k
  a <- r$mean * r$k
  n <- r$items

  ## use the estimate for n for the number of items with 0 occurrences
  obs[1] <- n - sum(obs)

  exp <- dnbinom(0:max(itemf), size = k, prob = 1 / (1 + a))

  if (plot) {
    observed <- n - cumsum(obs)
    expected <- n - n * cumsum(exp)
    maxx <- max(itemf)

    plot(
      0:maxx,
      observed,
      type = "l",
      xlab = "r",
      ylab = "n - cummulative frequency",
      xlim = c(0, maxx),
      ylim = c(0, max(observed, expected, na.rm = TRUE))
    )
    lines(0:maxx, expected, col = "red", lty = 2)
    legend(
      "topright",
      c("data", "model"),
      col = c(1, "red"),
      lty = c(1, 2),
      inset = 0.02
    )
  }

  a <- a  / length(data@data@i) ### a per incidence

  param <- new(
    "NBMinerParameter",
    pi = pi,
    theta = theta,
    n = n,
    k = k,
    a = a,
    rules = rules,
    minlen = as.integer(minlen),
    maxlen = as.integer(maxlen)
  )

  if (!getdata)
    param
  else
    list(parameter = param,
         obs = obs,
         exp = exp)
}



## estimate the parameters of the NBD distribution
## uses EM-Algorithm for missing zero-class
## Author: Michael Hahsler (michael@hahsler.net)
## License:  GPL version 2 or later.
##


## counts_hist is a vector starting with 0,1,2,...
.estim_nbinom <- function(counts_hist,
                          missing_zeros = FALSE,
                          tol = 0.0001,
                          trim = 0,
                          verb = FALSE) {
  items <- sum(counts_hist)
  r_max <- length(counts_hist)
  trimmed_items <- 0
  ## trim items from the tail
  if (trim > 0) {
    trimmed_items <- 0

    while (trimmed_items < items * trim) {
      trimmed_items <- trimmed_items + counts_hist[r_max]
      counts_hist[r_max] <- 0
      r_max <- r_max - 1
    }

    items <- sum(counts_hist)
    if (verb)
      cat(trimmed_items,
          "item(s) trimmed, leaving ",
          items,
          " items.",
          "\n")
  }

  ## clear trailing zeroes
  while (counts_hist[r_max] == 0)
    r_max <- r_max - 1
  length(counts_hist) <- r_max
  ## since we start with 0
  r_max <- r_max - 1

  if (missing_zeros == FALSE) {
    if (verb)
      cat("using method of moments\n")
    par = .estim_nbd_moments(counts_hist)
    return(
      list(
        items = items,
        trimmed_items = trimmed_items,
        r_max = r_max,
        mean = par$mean,
        k = par$k,
        var = par$var,
        counts_hist = counts_hist
      )
    )
  }

  ## now with missing zeros
  if (verb)
    cat("using Expectation Maximization for missing zero class\n")

  ## get start values for Expectation Maximization
  counts_hist[1] <- counts_hist[2] ### lower bound for 0 class
  par <- .estim_nbd_moments(counts_hist)

  k <- par$k
  m <- par$mean

  k_old <- 0
  i <- 0
  p0 <- 0

  while (abs(k - k_old) > tol) {
    i <- i + 1

    k_old <- k
    ## update zero class
    p0 <- dnbinom(0, size = k, mu = m)
    counts_hist[1] <- round(items / (1 - p0) * p0)

    ## estimate parameters (max. likelihood estimates are
    ## equal to meth. of moments)
    par <- .estim_nbd_moments(counts_hist)

    k <- par$k
    m <- par$mean

    if (verb)
      cat("iteration =",
          i,
          ", zero class =",
          counts_hist[1],
          ", k =",
          k,
          ", m =",
          m,
          "\n")

    if (is.na(k) || is.na(m) || is.na(p0))
      stop("Unable to fit distribution. Did you trim too many items?")
  }

  p_nbinom <- dnbinom(c(0:(r_max - 1)), size = k, mu = m)
  p_nbinom[r_max + 1] <- 1 - sum(p_nbinom)

  items <- items + counts_hist[1] ### add zero class
  if (verb)
    cat ("total items = ", items, "\n")

  list(
    items = as.integer(items),
    trimmed_items = as.integer(trimmed_items),
    r_max = as.integer(r_max),
    mean = m,
    k = k,
    var = par$var,
    p0 = p0,
    f0 = counts_hist[1],
    counts_hist = counts_hist,
    p_nbinom = p_nbinom
  )
}


.estim_nbd_moments <- function(counts_hist) {
  mv <- .mean_var_from_hist (counts_hist)
  k <- mv$mean^2 / (mv$var - mv$mean)
  list(k = k,
       mean = mv$mean,
       var = mv$var)
}


## get mean and var from a histogram with cells 0, 1, 2,...
.mean_var_from_hist <- function (counts_hist) {
  r_max <- length(counts_hist) - 1  ### since we start with 0
  items <- sum(counts_hist)

  m <- 1 / items * sum(counts_hist * seq.int(0, r_max))
  v <- 1 / (items - 1) * sum(counts_hist * ((seq.int(0, r_max) - m)^2))

  list(mean = m,
       var = v,
       items = items)
}


.chi2_test <- function (obs,
                        exp,
                        parameters = 3,
                        bins = NULL,
                        verb = FALSE) {
  ##
  ## bins is a list of index vectors to build classes
  ## e.g., list(c(0), c(1,2), c(3:7), c(7:100)) makes
  ## a bins for 1. r=0, 2. r=1 and 2, 3. r=3-6 and 4. r=7-100
  ##
  ## bins = NULL means no binning

  n <- sum(obs)

  if (!is.null(bins)) {
    bins <- as.list(bins)
    if (verb) {
      cat("Binning data\n")
    }
    obs <- sapply(bins, function(x)
      sum(obs[x + 1]))
    exp <- sapply(bins, function(x)
      sum(exp[x + 1]))

  }

  if (verb) {
    print(cbind(obs, exp = exp * n))
  }

  chitest <- chisq.test(obs, p = exp)
  chitest$prob <- pchisq(
    chitest$statistic,
    ##length(obs)-parameters-1,
    length(obs) - 1,
    log.p = FALSE,
    lower.tail = FALSE
  )
  attr(chitest$prob, "names") <- "p-value"


  chitest
}
