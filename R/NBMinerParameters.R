#' Estimate Global Model Parameters from Data
#'
#' Estimate the parameters for the global negative binomial independence
#' model used by NBMiner.
#'
#' The model is fit using observed item frequencies in the data.
#' The expectation maximization (EM) algorithm (Dempster et al, 1977)
#' is used to estimate the
#' global NB model because
#' the zero class (missing values representing items that do not occur in
#' the dataset) is not observed.
#' This procedure iteratively estimates missing values using the observed data
#' and the model using intermediate values of the parameters,
#' and then uses the estimated data and the observed data to update the
#' parameters for the next iteration.
#' The procedure stops when the parameters stabilize.
#'
#' Another common issue is the presence of outliers with unusually high frequencies.
#' These outliers will distort the mean and the variance and thus will lead
#' to a model that grossly overestimates the probability of seeing items with
#' high frequencies. For a more robust estimate, we can trim a
#' suitable percentage of the items with the highest frequencies.
#' A suitable percentage can be found by visual comparison of the empirical
#' data and the estimated model or by minimizing the
#' \eqn{\chi^2}{Chi-squared}-value of the goodness-of-fit test which is
#' reported when run with `verbose = TRUE`. A diagnostic plot
#' comparing the observed data with the model is shown with `plot = TRUE`.
#' The plot shows the number of items with a frequency larger than \eqn{r}.
#'
#' The result is the
#' two NB parameters \eqn{k} and \eqn{a}, but note that \eqn{a} is rescaled by
#' dividing it by the number of incidences in the data, as required by NBMiner.
#' The estimated total number of items \eqn{n} including the fitted number of
#' unseen items (items with a frequency of 0) is also returned.
#'
#' Only `data` and `trim` are used for the estimation. `bins` can be used to
#' change the number of bins used in the goodness-of-fit test. The other
#' parameters are stored in the parameter object for use by [NBMiner()].
#'
#' @param data the data as an object of class [`arules::transactions`].
#' @param trim fraction of the most frequent items to exclude when fitting the
#'   baseline model.
#' @param pi minimum predicted precision required to accept an itemset
#'   extension or rule.
#' @param theta fraction of an itemset's immediate subsets that must be
#'   NB-frequent for the itemset to be considered during search.
#' @param bins number of bins used for the chi-squared goodness-of-fit test.
#' @param minlen minimum number of items in returned itemsets (default: 1).
#' @param maxlen maximum number of items in returned itemsets (default: 5).
#' @param rules whether to mine NB-precise rules instead of NB-frequent
#'   itemsets.
#' @param plot whether to plot the observed and fitted frequency distributions.
#' @param verbose whether to print progress and goodness-of-fit results.
#' @param getdata whether to return the parameter object together with observed
#'   counts, expected counts, and the chi-squared test result.
#' @return An object of class `NBMinerParameter` for use with [NBMiner()]. If
#' `getdata = TRUE`, a list containing the parameter object, observed counts,
#' expected counts, and the result of the chi-squared test is returned.
#' @references Michael Hahsler. A model-based frequency constraint for mining
#' associations from transaction data. _Data Mining and Knowledge
#' Discovery_,13(2):137-166, September 2006.
#' \doi{10.1007/s10618-005-0026-2}
#'
#' Dempster, A. P., Laird, N. M., and Rubin, D. B. (1977).
#' Maximum likelihood from incomplete data via the EM algorithm.
#' _Journal of the Royal Statistical Society, Series B (Methodological),_
#' 39:1–38.
#' \doi{10.1111/j.2517-6161.1977.tb01600.x}
#' @keywords models
#' @examples
#' data("Epub")
#' Epub
#'
#' param <- NBMinerParameters(Epub, trim = 0.04)
#' param
#'
NBMinerParameters <- function(data,
                              trim = 0.01,
                              pi = 0.99,
                              theta = 0.5,
                              bins = 10,
                              minlen = 1,
                              maxlen = 5,
                              rules = FALSE,
                              plot = TRUE,
                              verbose = TRUE,
                              getdata = FALSE) {
  itemf <- itemFrequency(data, type = "abs")

  ## the number of items with 0 occurrences is unobservable
  obs <- c(0, tabulate(itemf))
  r <- .estim_nbinom(obs,
                     trim = trim,
                     missing_zeros = TRUE,
                     verbose = verbose)

  k <- r$k
  a <- r$mean * r$k
  n <- r$items

  ## use the estimate for n for the number of items with 0 occurrences
  # Note: obs[1] can get negative here!
  obs[1] <- n - sum(obs)
  exp <- dnbinom(0:max(itemf), size = k, prob = 1 / (1 + a))

  # warns for bins with low counts
  chitest <- suppressWarnings(.chi2_test(obs, exp, bins = bins))

  if (verbose) {
    cat("\nGoodness of fit/chi-square test on binned count data\n")
    cat("  H0: Observed counts match the expected proportions.\n")
    cat("  Bins: ", bins, "\n")
    cat("  X-squared = ", chitest$statistic, " with ",
        chitest$parameter," degrees of freedom\n")
    cat("  p.value = ", chitest$p.value, "\n\n")
  }

  if (plot) {
    observed <- n - cumsum(obs)
    expected <- n - n * cumsum(exp)
    maxx <- max(itemf)

    plot(
      0:maxx,
      observed,
      type = "l",
      main = "NB model fit to data",
      xlab = "item frequency r",
      ylab = "number of items with frequency > r",
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
         exp = exp,
         chisq = chitest)
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
                          verbose = FALSE) {
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
    if (verbose)
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
    if (verbose)
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
  if (verbose)
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

    if (verbose)
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
  if (verbose)
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
                        bins = 20,
                        verbose = FALSE) {
  # obs ... counts
  # exp ... probabilities

  n <- sum(obs)

  # exclude 0 counts
  obs <- obs[-1]
  exp <- exp[-1]

  # bin data
  cuts <- cut(seq_along(obs), breaks = bins, labels = FALSE)
  obs <- sapply(seq_len(bins), FUN = function(i) sum(obs[i]))
  exp <- sapply(seq_len(bins), FUN = function(i) sum(exp[i]))

  if (verbose) {
    print(cbind(obs, exp = exp * n))
  }

  # make sure exp sums up to 1
  exp <- exp / sum(exp)

  chisq.test(obs, p = exp)
}
