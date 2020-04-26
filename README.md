# arulesNBMiner - Mining NB-Frequent Itemsets and NB-Precise Rules - R package

[![CRAN version](https://www.r-pkg.org/badges/version/arulesNBMiner)](https://CRAN.R-project.org/package=arulesNBMiner) 
[![CRAN RStudio mirror downloads](https://cranlogs.r-pkg.org/badges/arulesNBMiner)](https://CRAN.R-project.org/package=arulesNBMiner)
[![Travis-CI Build Status](https://travis-ci.org/mhahsler/arulesNBMiner.svg?branch=master)](https://travis-ci.org/mhahsler/arulesNBMiner)
[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/mhahsler/arulesNBMiner?branch=master&svg=true)](https://ci.appveyor.com/project/mhahsler/arulesNBMiner)

This R package 
extends package [arules](https://github.com/mhahsler/arules) with
NBMiner, an implementation of the model-based mining algorithm 
    for mining NB-frequent itemsets presented in "Michael Hahsler. [A
    model-based frequency constraint for mining associations from
    transaction data.](http://dx.doi.org/10.1007/s10618-005-0026-2) _Data Mining and Knowledge Discovery,_ 13(2):137-166, September 2006." 
    In addition an extension for NB-precise rules is implemented. 

## Installation

__Stable CRAN version:__ install from within R with
```R
install.packages("arulesNBMiner")
```
__Current development version:__ Download package from [AppVeyor](https://ci.appveyor.com/project/mhahsler/arulesNBMiner/build/artifacts) or install from GitHub (needs devtools).
```R 
install_git("mhahsler/arulesNBMiner")
```


## Usage

Estimate NBD model parameters
```R
library(arulesNBMiner)
data("Agrawal")
param <- NBMinerParameters(Agrawal.db, pi=0.99, theta=0.5, maxlen=5,
     minlen=1, trim = 0, verb = TRUE, plot=TRUE) 
```

```
using Expectation Maximization for missing zero class
iteration = 1 , zero class = 2 , k = 1.08506 , m = 278.7137 
total items =  716 
```

Mine NB-frequent itemsets
```R
itemsets_NB <- NBMiner(Agrawal.db, parameter = param, 
     control = list(verb = TRUE, debug=FALSE))
```

```
parameter specification:
   pi theta   n       k           a minlen maxlen rules
 0.99   0.5 716 1.08506 0.001515447      1      5 FALSE

algorithmic control:
 verbose debug
    TRUE FALSE

Depth-first NB-frequent itemset miner by Michael Hahsler
Database with 20000 transactions and 1000 unique items

3507 NB-frequent itemsets found.
```

```R
inspect(head(itemsets_NB))
```

```
  items                                     precision
1 {item494,item525,item572,item765,item775} 1.0000000
2 {item398,item490,item848}                 1.0000000
3 {item292,item793,item816}                 1.0000000
4 {item229,item780}                         0.9964852
5 {item111,item149,item715}                 1.0000000
6 {item91,item171,item902}                  1.0000000
```

## References

* Michael Hahsler, [A
    model-based frequency constraint for mining associations from
    transaction data.](http://dx.doi.org/10.1007/s10618-005-0026-2)
     _Data Mining and Knowledge Discovery,_ 13(2):137-166,
    September 2006. 
    [Free preprint](http://michael.hahsler.net/research/nbd_dami2005/nbd_associationrules_dami2005.pdf)
* Michael Hahsler, Sudheer Chelluboina, Kurt Hornik, and Christian Buchta. [The arules R-package ecosystem: Analyzing interesting patterns from large transaction datasets.](http://jmlr.csail.mit.edu/papers/v12/hahsler11a.html) _Journal of Machine Learning Research,_ 12:1977-1981, 2011.

