#' NBMiner: Mine NB-Frequent Itemsets or NB-Precise Rules
#'
#' Mines NB-frequent itemsets or NB-precise rules.
#'
#' Mines NB-frequent itemsets or NB-precise rules (Hahsler, 2006) are non-spurious
#' patterns that occur significantly more often in the data than
#' one would expect if the items were independent.
#' Under independence, we model each item's frequency as a Poisson count
#' with an item specific rate, and models variation in those
#' rates with a Gamma distribution. Mixing the Poisson counts over the Gamma
#' rates gives a negative binomial distribution. This flexible baseline
#' captures the skewed frequency distributions common in transaction data:
#' a few items occur often, while many occur rarely.
#' The model parameters for the independence model can be estimated from the data
#' using [NBMinerParameters()].
#'
#' NBMiner considers for an itemset adding each possible other item.
#' Given the independent baseline it predicts how many extensions would reach
#' each frequency by chance. The `pi` parameter sets the minimum predicted
#' precision for accepting extensions. Here, precision means the predicted
#' proportion of accepted extensions that are true associations under the model.
#' Only extensions with a precision of at least `pi` are accepted.
#'
#' The `theta` parameter controls pruning during search. For a larger itemset,
#' it sets the required fraction of its immediate subsets that must support the
#' itemset as an NB-frequent pattern. A value of 1 is most restrictive requiring
#' all subsets also to be NB-frequent;
#' 0 relaxes this condition. The intermediate default value 0.5 balances
#' pruning with the chance of retaining associations whose items have
#' different frequencies.
#'
#' `maxlen` limits the longest itemset considered, and `minlen` can set a
#' minimum length for returned patterns.
#'
#' The mining algorithm uses a depth-first search implemented in Java.
#'
#' Details can be found in Hahsler (2006).
#'
#' @aliases NBMiner NBMinerControl-class NBMinerParameter-class
#' @param data object of class [`arules::transactions`].
#' @param parameter an `NBMinerParameter` object or a named list of its
#'   parameters. Use [NBMinerParameters()] to estimate the model parameters.
#' @param control an `NBMinerControl` object or a named list of control
#'   options. `verbose` and `debug` are logical options that control progress
#'   and diagnostic output.
#' @param ... named parameter overrides applied to `parameter` before mining.
#'   For example, use `rules = TRUE` to mine rules or change `pi` or `theta`.
#' @return An object of class [`arules::itemsets`] or [`arules::rules`], depending
#' on the `rules` parameter. Estimated precision is stored in the quality slot.
#' @references Michael Hahsler. A model-based frequency constraint for mining
#' associations from transaction data. _Data Mining and Knowledge
#' Discovery_, 13(2):137-166, September 2006.
#' \doi{10.1007/s10618-005-0026-2}
#' @keywords models
#' @examples
#' data("Agrawal")
#'
#' # Estimate independence model parameters
#' param <- NBMinerParameters(Agrawal.db, trim = 0)
#'
#' # Mine non-spurious patterns
#' itemsets_NB <- NBMiner(Agrawal.db,
#'                        parameter = param,
#'                        pi = 0.99,
#'                        theta = 0.5,
#'                        minlen = 2L)
#'
#' inspect(head(itemsets_NB))
#'
#' # Compare with the known patterns used to generate the data
#' num_correct <- function(itemsets, patterns)
#'     table(factor(rowSums(is.subset(itemsets, patterns)) > 0,
#'           c(FALSE, TRUE)))
#'

#' # How many found itemsets are subsets of the patterns used in the db?
#' num_correct(itemsets_NB, Agrawal.pat)
#'
#' # Compare with the same number of the most frequent itemsets
#' itemsets_supp <-  eclat(Agrawal.db, parameter = list(supp = 0.001, minlen = 2))
#' itemsets_supp <- head(sort(itemsets_supp, by = "support"), length(itemsets_NB))
#' num_correct(itemsets_supp, Agrawal.pat)
#'
#' # we see that NBMiner is much more effective to recover the true patterns.
#'
#'
#' # Mine NB-precise rules
#' rules_NB <- NBMiner(Agrawal.db,
#'                     parameter = param,
#'                     pi = 0.99,
#'                     theta = 0.5,
#'                     rules = TRUE)
#' rules_NB
#'
#' inspect(head(rules_NB))
NBMiner <- function(data, parameter, control = NULL, ...) {
  data <- as(data, "transactions")
  control <- as(control, "NBMinerControl")
  parameter <- as(parameter, "NBMinerParameter")

  ### add ... to parameters
  additional_param <- list(...)
  slots <- getSlots("NBMinerParameter")
  for (n in names(additional_param)) {
    if (!(n %in% names(slots)))
      stop("Unknown parameter: ", n)
    slot(parameter, n) <- as(additional_param[[n]], slots[n])
  }

  if (control@verbose) {
    ## print parameter
    cat("\nparameter specification:\n")
    print(parameter)
    cat("\nalgorithmic control:\n")
    print(control)
    cat("\n")
  }

  ## create DB
  db <- .jnew("SparseSetOfItemsets", data@data@i, data@data@p, dim(data)[2])

  ## call NBMiner
  miner <- .jnew("NBMiner")
  result <- .jcall(
    miner,
    "LR_result;",
    "R_mine",
    db,
    parameter@pi,
    parameter@theta,
    parameter@a,
    parameter@k,
    parameter@n,
    parameter@maxlen,
    parameter@rules,
    control@verbose,
    control@debug
  )

  ## get result
  .as_itemMatrix <- function(x) {
    m <- new(
      "ngCMatrix",
      i = .jcall(x, "[I", "getI"),
      p = .jcall(x, "[I", "getP"),
      Dim = c(.jcall(x, "I", "getItems"), .jcall(x, "I", "size"))
    )

    new("itemMatrix", data = m, itemInfo = itemInfo(data))
  }

  ## get precision
  precision <- .jcall(result, "[D", "getPrecision")

  ## encode as rules/itemsets
  res <- if (parameter@rules)
    new(
      "rules",
      lhs = .as_itemMatrix(.jcall(
        result, "LSparseSetOfItemsets;", "getLhs"
      )),
      rhs = .as_itemMatrix(.jcall(
        result, "LSparseSetOfItemsets;", "getRhs"
      )),
      quality = data.frame(precision = precision)
    )
  else
    new("itemsets",
        items = .as_itemMatrix(.jcall(
          result, "LSparseSetOfItemsets;", "getItems"
        )),
        quality = data.frame(precision = precision))

  ## remove itemsets/rules that are too short
  if (parameter@minlen > 1)
    res <- res[size(res) >= parameter@minlen]
  res
}
