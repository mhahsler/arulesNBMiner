#' NBMiner: Mine NB-Frequent Itemsets or NB-Precise Rules
#'
#' Calls the Java implementation of the depth first search algorithm described
#' in the paper in the references section to mine NB-frequent itemsets of
#' NB-precise rules.
#'
#' The parameters can be estimated from the data using
#' \code{NBMinerParameters}.
#'
#' @aliases NBMiner NBMinerControl-class NBMinerParameter-class
#' @param data object of class [arules::transactions].
#' @param parameter a list of parameters (automatically converted into an
#' object of class \code{NBMinerParameter}). Reasonable parameters can be
#' obtained using [NBMinerParameters()] (see details section).
#' @param control a list of control options (automatically converted into an
#' object of class \code{NBMinerControl}). Currently only \code{"verbose"} and
#' \code{"debug"} (both logical) are available.
#' @return An object of class [arules::itemsets] or [arules::rules] (depending on the rules entry
#' in parameter). The estimated precision is stored in the quality slot.
#' @references Michael Hahsler. A model-based frequency constraint for mining
#' associations from transaction data. \emph{Data Mining and Knowledge
#' Discovery, 13(2):137-166,} September 2006.
#' \doi{10.1007/s10618-005-0026-2}
#' @keywords models
#' @examples
#' data("Agrawal")
#'
#' ## mine
#' param <- NBMinerParameters(Agrawal.db, pi = 0.99, theta = 0.5, maxlen = 5,
#'     minlen=1, trim = 0, verbose = TRUE, plot = TRUE)
#' itemsets_NB <- NBMiner(Agrawal.db, parameter = param,
#'     control = list(verbose = TRUE, debug = FALSE))
#'
#' inspect(head(itemsets_NB))
#'
#' ## remove patterns of length 1 (noise)
#' i_NB <- itemsets_NB[size(itemsets_NB) > 1]
#' patterns <- Agrawal.pat[size(Agrawal.pat) > 1]
#'
#' ## how many found itemsets are subsets of the patterns used in the db?
#' table(rowSums(is.subset(i_NB,patterns)) > 0)
#'
#' ## compare with the same number of the most frequent itemsets
#' itemsets_supp <-  eclat(Agrawal.db, parameter = list(supp = 0.001))
#' i_supp <- itemsets_supp[size(itemsets_supp) > 1]
#' i_supp <- head(sort(i_supp, by = "support"), length(i_NB))
#' table(rowSums(is.subset(i_supp, patterns)) > 0)
#'
#' ## mine NB-precise rules
#' param <- NBMinerParameters(Agrawal.db, pi = 0.99, theta = 0.5, maxlen = 5,
#'     rules = TRUE, minlen = 1, trim = 0)
#' rules_NB <- NBMiner(Agrawal.db, parameter = param,
#'     control = list(verbose = TRUE, debug = FALSE))
#'
#' inspect(head(rules_NB))
#'
NBMiner <- function(data, parameter, control = NULL) {
  data <- as(data, "transactions")
  #parameter <- as(parameter, "NBMinerParameter")
  control <- as(control, "NBMinerControl")

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
