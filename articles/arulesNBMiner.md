# Getting started with arulesNBMiner

`arulesNBMiner` extends the `arules` package with NBMiner, which mines
negative-binomial (NB) frequent itemsets and NB-precise association
rules. This vignette demonstrates the workflow with the package’s
bundled Agrawal transactions. NBMiner uses a model-based frequency
constraint described by Hahsler (2006). A single minimum-support
threshold can miss associations involving infrequent items and tends to
favor short itemsets. The model-based constraint adapts its frequency
threshold to each itemset extension, using an estimated baseline for how
often independent items would co-occur.

## Load the data

Load the package and its example data. `Agrawal.db` is a `transactions`
object, the input format used by `arulesNBMiner`.

``` r

library(arulesNBMiner)
#> Loading required package: arules
#> Loading required package: Matrix
#> 
#> Attaching package: 'arules'
#> The following objects are masked from 'package:base':
#> 
#>     abbreviate, write
#> Loading required package: rJava
data("Agrawal")
summary(Agrawal.db)
#> transactions as itemMatrix in sparse format with
#>  20000 rows (elements/itemsets/transactions) and
#>  1000 columns (items) and a density of 0.0099933 
#> 
#> most frequent items:
#> item446 item938 item818 item457 item401 (Other) 
#>    1638    1514    1450    1397    1389  192478 
#> 
#> element (itemset/transaction) length distribution:
#> sizes
#>    1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16 
#>   16   68  215  427  763 1234 1813 2215 2341 2437 2320 1896 1457 1045  739  447 
#>   17   18   19   20   21   22   23   24 
#>  260  171   74   25   16   15    2    4 
#> 
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   1.000   8.000  10.000   9.993  12.000  24.000 
#> 
#> includes extended item information - examples:
#>   labels
#> 1  item1
#> 2  item2
#> 3  item3
#> 
#> includes extended transaction information - examples:
#>   transactionID
#> 1        trans1
#> 2        trans2
#> 3        trans3
```

## Fit the baseline model

The paper models each item’s frequency as a Poisson count with an item
specific rate, and models variation in those rates with a Gamma
distribution. Mixing the Poisson counts over the Gamma rates gives a
negative binomial distribution. This flexible baseline captures the
skewed frequency distributions common in transaction data: a few items
occur often, while many occur rarely.

[`NBMinerParameters()`](https://michael.hahsler.net/arulesNBMiner/reference/NBMinerParameters.md)
estimates this global model from the item frequencies. Items that never
occur are absent from the transactions, so the estimator uses an
expectation-maximization procedure to estimate the unobserved zero
frequency class. The `trim` argument can exclude the most frequent items
when they are outliers that would distort the fit. Inspect the
diagnostic plot before choosing a nonzero trim value.

``` r

param <- NBMinerParameters(Agrawal.db, 
                           pi = 0.99, 
                           theta = 0.5, 
                           maxlen = 5, 
                           minlen = 1,
                           trim = 0, 
                           verbose = TRUE, 
                           plot = TRUE)
#> using Expectation Maximization for missing zero class
#> iteration = 1 , zero class = 3 , k = 0.9862909 , m = 277.9777 
#> iteration = 2 , zero class = 3 , k = 0.9862909 , m = 277.9777 
#> total items =  719
```

![](arulesNBMiner_files/figure-html/parameters-1.png)

``` r


param
#>    pi theta   n         k           a minlen maxlen rules
#>  0.99   0.5 719 0.9862909 0.001371754      1      5 FALSE
```

The figure compares the observed cumulative item frequencies with
frequencies expected under the fitted baseline. The `a` estimate is
scaled per incidence for NBMiner, as described in the paper.

## Mine NB-frequent itemsets

For an itemset already found, NBMiner considers adding each possible
item. It fits the baseline to the transactions containing that itemset
and predicts how many extensions would reach each frequency by chance.
The `pi` parameter sets the minimum predicted precision for accepting
extensions. Here, precision means the predicted proportion of accepted
extensions that are true associations under the model; it is not a
guarantee of the actual precision for every data set.

The `theta` parameter controls search pruning. For a larger itemset, it
sets the required fraction of its immediate subsets that must support
the itemset as an NB-frequent pattern. A value of 1 is most restrictive;
0 relaxes this condition. The intermediate value 0.5 used here balances
pruning with the chance of retaining associations whose items have
different frequencies. `maxlen` limits the longest itemset considered,
and `minlen` can set a minimum length for returned patterns. The
`control` list accepts `verbose` and `debug` logical options.

Results include model-estimated precision in the `precision` quality
column. For comparison, we add the support measure.

``` r

itemsets <- NBMiner(
  Agrawal.db,
  parameter = param,
  control = list(verbose = FALSE, debug = FALSE)
)

quality(itemsets) <- cbind(quality(itemsets),
                           support = interestMeasure(itemsets, "support", 
                                           transactions = Agrawal.db))

inspect(head(sort(itemsets, by = "support"), n = 10))
#>      items     precision support
#> [1]  {item446} 1         0.08190
#> [2]  {item938} 1         0.07570
#> [3]  {item818} 1         0.07250
#> [4]  {item457} 1         0.06985
#> [5]  {item401} 1         0.06945
#> [6]  {item453} 1         0.06895
#> [7]  {item355} 1         0.06880
#> [8]  {item238} 1         0.06765
#> [9]  {item615} 1         0.06720
#> [10] {item318} 1         0.06220
```

## Mine NB-precise rules

NB-precise rules are rules created from NB-frequent itemsets. Rules
instead of itemsets can be mined by changing the parameter element
`rules` to `TRUE`.

For comparison, we add the standard measures support, confidence, and
lift.

``` r

param@rules <- TRUE

rules <- NBMiner(Agrawal.db, parameter = param)

quality(rules) <- cbind(quality(rules),
                           interestMeasure(rules, c("support", "confidence", "lift"), 
                                           transactions = Agrawal.db))

inspect(head(sort(rules, by = "precision"), n = 10))
#>      lhs                   rhs       precision support confidence lift    
#> [1]  {item220, item964} => {item956} 1         0.01100 0.9649123  75.67939
#> [2]  {item220, item452} => {item956} 1         0.01155 0.9625000  75.49020
#> [3]  {item510, item885} => {item667} 1         0.01180 0.8773234  26.82946
#> [4]  {item452, item964} => {item956} 1         0.01115 0.9695652  76.04433
#> [5]  {item889}          => {item860} 1         0.00990 0.8839286  37.21805
#> [6]  {item848}          => {item152} 1         0.00775 0.6126482  10.50855
#> [7]  {item167, item552} => {item959} 1         0.01215 0.9310345  24.59800
#> [8]  {item987}          => {item320} 1         0.00960 0.8170213  17.83889
#> [9]  {item529, item627} => {item940} 1         0.01075 0.9071730  26.10570
#> [10] {item707}          => {item394} 1         0.00865 0.8046512  19.48308
```

The rules are very unlikely to random noise in the data.

## References

Hahsler, M. (2006). [A model-based frequency constraint for mining
associations from transaction
data](https://doi.org/10.1007/s10618-005-0026-2). *Data Mining and
Knowledge Discovery*, 13(2), 137–166. [Full text on
arXiv](https://arxiv.org/pdf/0803.3224).
