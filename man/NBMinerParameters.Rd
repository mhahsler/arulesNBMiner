\name{NBMinerParameters}
\alias{NBMinerParameters}
\title{Estimate Global Model Parameters from Data}
\description{
Estimate the global negative binomial data model used by the NBMiner and
create an appropriate parameter object.
}
\usage{
NBMinerParameters(data, trim = 0.01, pi = 0.99, theta = 0.5,
    minlen = 1, maxlen = 5, rules = FALSE,
    plot = FALSE, verbose = FALSE, getdata = FALSE)
}
\arguments{
  \item{data}{ the data as a object of class transactions. }
  \item{trim}{ fraction of incidences to trim off the tail of the 
  frequency distribution of the data. }
  \item{pi}{ precision threshold \eqn{\pi}. }
  \item{theta}{ pruning parameter \eqn{\theta}. }
  \item{minlen}{ minimum number of items in found itemsets (default: 1). }
  \item{maxlen}{ maximal number of items in found itemsets (default: 5). }
  \item{rules}{ mine NB-precise rules instead of NB-frequent itemsets?}
  \item{plot}{ plot the model? }
  \item{verbose}{ use verbose output for the estimation procedure. }
  \item{getdata}{ get also the observed and estimated counts. }
}
\details{
Uses the EM algorithm to estimate the global NB model for the data.
The EM algorithm is used since the zero class (items which do not occur
in the dataset) is not included in the data. The result are the two
NB parameters \eqn{k} and \eqn{a}, where \eqn{a} is rescaled by dividing
it by the number of incidences in the data (this is needed by the NBMiner).
Also the real number of items \eqn{n} is a result of the estimation.

\code{theta} and \code{pi} are just taken and added to the resulting 
parameter object.
}
\value{
an object of class \code{NBMinerParameter} for \code{NBMiner}.
}
\references{
Michael Hahsler. A model-based frequency constraint for mining associations
from transaction data. \emph{Data Mining and Knowledge
Discovery,13(2):137-166,} September 2006.
}
\seealso{\code{\link{NBMiner}}, \code{\link[arules]{transactions-class}}}
\examples{
data("Epub")

param <- NBMinerParameters(Epub, trim = 0.05, plot = TRUE, verbose = TRUE)
param
}
\keyword{models}
