# arulesNBMiner - Mining NB-Frequent Itemsets and NB-Precise Rules - R package

[![CRAN version](http://www.r-pkg.org/badges/version/arulesNBMiner)](http://cran.r-project.org/web/packages/arulesNBMiner/index.html)
[![CRAN RStudio mirror downloads](http://cranlogs.r-pkg.org/badges/arulesNBMiner)](http://cran.r-project.org/web/packages/arulesNBMiner/index.html)
[![Travis-CI Build Status](https://travis-ci.org/mhahsler/arulesNBMiner.svg?branch=master)](https://travis-ci.org/mhahsler/arulesNBMiner)
[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/mhahsler/arulesNBMiner?branch=master&svg=true)](https://ci.appveyor.com/project/mhahsler/arulesNBMiner)

This R package 
extends package [arules](http://github.com/mhahsler/arules) with
NBMiner, an implementation of the model-based mining algorithm 
    for mining NB-frequent itemsets presented in ["Michael Hahsler. A
    model-based frequency constraint for mining associations from
    transaction data. Data Mining and Knowledge Discovery, 13(2):137-166,
    September 2006."](http://dx.doi.org/10.1007/s10618-005-0026-2) In addition an extension for NB-precise rules is 
    implemented. 

## Installation

* __Stable CRAN version:__ install from within R.
* __Current development version:__ Download package from [AppVeyor](https://ci.appveyor.com/project/mhahsler/arulesNBMiner/build/artifacts) or install via `intall_git("mhahsler/arulesNBMiner")` (requires devtools). You
might also have to install the development version of [arules](http://github.com/mhahsler/arules).

## Example
```R
R> library(arulesNBMiner)
R> data("Agrawal")
 
# estimate NBD model parameters
R> param <- NBMinerParameters(Agrawal.db, pi=0.99, theta=0.5, maxlen=5,
+     minlen=1, trim = 0, verb = TRUE, plot=TRUE) 

using Expectation Maximization for missing zero class
iteration = 1 , zero class = 2 , k = 1.08506 , m = 278.7137 
total items =  716 

# mine rules
R> itemsets_NB <- NBMiner(Agrawal.db, parameter = param, 
+     control = list(verb = TRUE, debug=FALSE))

parameter specification:
   pi theta   n       k           a minlen maxlen rules
 0.99   0.5 716 1.08506 0.001515447      1      5 FALSE

algorithmic control:
 verbose debug
    TRUE FALSE

Depth-first NB-frequent itemset miner by Michael Hahsler
Database with 20000 transactions and 1000 unique items

3507 NB-frequent itemsets found.

R> inspect(head(itemsets_NB))
  items                                     precision
1 {item494,item525,item572,item765,item775} 1.0000000
2 {item398,item490,item848}                 1.0000000
3 {item292,item793,item816}                 1.0000000
4 {item229,item780}                         0.9964852
5 {item111,item149,item715}                 1.0000000
6 {item91,item171,item902}                  1.0000000
```

## Further Information

* [Reference manual](http://cran.r-project.org/web/packages/arulesNBMiner/arulesNBMiner.pdf)

