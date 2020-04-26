\name{NBMiner}
\alias{NBMiner}
\alias{NBMinerControl-class}
\alias{NBMinerParameter-class}
\title{NBMiner: Mine NB-Frequent Itemsets or NB-Precise Rules}
\description{
 Calls the Java implementation of the depth first search algorithm
 described in the paper in the references section to mine NB-frequent
 itemsets of NB-precise rules.
}
\usage{
NBMiner(data, parameter, control = NULL)
}
\arguments{
  \item{data}{ object of class transactions. }
  \item{parameter}{ a list of parameters (automatically converted into an
  object of class \code{NBMinerParameter}). Reasonable parameters can be
  obtained using \code{NBMinerParameters} (see details section).}
  \item{control}{ a list of control options (automatically converted into an
    object of class \code{NBMinerControl}). Currently only 
    \code{"verbose"} and \code{"debug"} (both logical) are available.}
}
\details{
 The parameters can be estimated from the data using \code{NBMinerParameters}.
}
\value{
    An object of class itemsets or rules 
    (depending on the rules entry in parameter). The estimated precision is
    stored in the quality slot.
}
\references{ 
Michael Hahsler. A model-based frequency constraint for mining
associations from transaction data. \emph{Data Mining and Knowledge Discovery,
13(2):137-166,} September 2006. \doi{10.1007/s10618-005-0026-2} 
}
\seealso{\code{\link{NBMinerParameters}}, 
    \code{\link[arules]{transactions-class}},
    \code{\link[arules]{itemsets-class}},
    \code{\link[arules]{rules-class}}
    }
\examples{
data("Agrawal")

## mine
param <- NBMinerParameters(Agrawal.db, pi=0.99, theta=0.5, maxlen=5,
    minlen=1, trim = 0, verb = TRUE, plot=TRUE) 
itemsets_NB <- NBMiner(Agrawal.db, parameter = param, 
    control = list(verb = TRUE, debug=FALSE))

inspect(head(itemsets_NB))

## remove patterns of length 1 (noise)
i_NB <- itemsets_NB[size(itemsets_NB)>1]
patterns <- Agrawal.pat[size(Agrawal.pat)>1]

## how many found itemsets are subsets of the patterns used in the db?
table(rowSums(is.subset(i_NB,patterns))>0)

## compare with the same number of the most frequent itemsets
itemsets_supp <-  eclat(Agrawal.db, parameter=list(supp=0.001))
i_supp <- itemsets_supp[size(itemsets_supp) >1]
i_supp <- head(sort(i_supp, by = "support"), length(i_NB))
table(rowSums(is.subset(i_supp,patterns))>0)

## mine NB-precise rules
param <- NBMinerParameters(Agrawal.db, pi=0.99, theta=0.5, maxlen=5,
    rules=TRUE, minlen=1, trim = 0) 
rules_NB <- NBMiner(Agrawal.db, parameter = param, 
    control = list(verb = TRUE, debug=FALSE))

inspect(head(rules_NB))
}
\keyword{models}
