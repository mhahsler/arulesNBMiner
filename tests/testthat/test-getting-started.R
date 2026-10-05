test_that("model parameters can be estimated from transactions", {
  data("Agrawal")

  parameter <- NBMinerParameters(
    Agrawal.db,
    pi = 0.99,
    theta = 0.5,
    maxlen = 3,
    trim = 0
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
    trim = 0
  )
  itemsets <- NBMiner(Agrawal.db, parameter = itemset_parameter)

  expect_s4_class(itemsets, "itemsets")
  expect_true("precision" %in% names(slot(itemsets, "quality")))

  rule_parameter <- NBMinerParameters(
    Agrawal.db,
    pi = 0.99,
    theta = 0.5,
    maxlen = 3,
    trim = 0,
    rules = TRUE
  )
  rules <- NBMiner(Agrawal.db, parameter = rule_parameter)

  expect_s4_class(rules, "rules")
  expect_true("precision" %in% names(slot(rules, "quality")))
})
