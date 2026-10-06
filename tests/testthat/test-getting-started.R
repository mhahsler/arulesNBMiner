test_that("model parameters can be estimated from transactions", {
  data("Agrawal")

  parameter <- NBMinerParameters(
    Agrawal.db,
    pi = 0.99,
    theta = 0.5,
    maxlen = 3,
    trim = 0,
    plot = FALSE,
    verbose = FALSE
  )

  expect_s4_class(parameter, "NBMinerParameter")
  expect_true(is.finite(parameter@k))
  expect_true(is.finite(parameter@a))
  expect_gt(parameter@n, 0)
})

test_that("NBMiner returns itemsets and NB-precise rules", {
  data("Agrawal")

  itemset_parameter <- NBMinerParameters(
    Agrawal.db,
    pi = 0.99,
    theta = 0.5,
    maxlen = 3,
    trim = 0,
    plot = FALSE,
    verbose = FALSE
  )
  itemsets <- NBMiner(Agrawal.db, parameter = itemset_parameter, minlen = 2L)

  expect_s4_class(itemsets, "itemsets")
  expect_true("precision" %in% names(slot(itemsets, "quality")))
  expect_true(all(size(itemsets) >= 2L))

  rule_parameter <- NBMinerParameters(
    Agrawal.db,
    pi = 0.99,
    theta = 0.5,
    maxlen = 3,
    trim = 0,
    rules = TRUE,
    plot = FALSE,
    verbose = FALSE
  )
  rules <- NBMiner(Agrawal.db, parameter = rule_parameter)

  expect_s4_class(rules, "rules")
  expect_true("precision" %in% names(slot(rules, "quality")))
})

test_that("parameter estimation returns goodness-of-fit data", {
  data("Agrawal")

  result <- NBMinerParameters(
    Agrawal.db,
    trim = 0,
    bins = 8,
    plot = FALSE,
    verbose = FALSE,
    getdata = TRUE
  )

  expect_named(result, c("parameter", "obs", "exp", "chisq"))
  expect_s4_class(result$parameter, "NBMinerParameter")
  expect_length(result$chisq$statistic, 1)
  expect_true(is.finite(result$chisq$statistic))
  expect_equal(sum(result$obs), result$parameter@n)
})
