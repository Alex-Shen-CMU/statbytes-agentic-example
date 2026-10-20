# Generic K-fold cross-validation utilities.
#
# A "fitter" is a function(train) that returns a prediction function
# function(newdata) -> numeric vector of predicted log prices.

# Assign fold ids 1..K. If `strata` is given, folds are balanced within each
# stratum so every level with >= K observations appears in every fold.
make_folds <- function(n, K = 5, strata = NULL, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  if (is.null(strata)) return(sample(rep_len(seq_len(K), n)))
  folds <- integer(n)
  for (idx in split(seq_len(n), strata)) {
    folds[idx] <- sample(rep_len(sample(seq_len(K)), length(idx)))
  }
  folds
}

rmse <- function(y, yhat) sqrt(mean((y - yhat)^2))

# Out-of-fold RMSE of `fitter` on `data`. Returns per-fold errors and their mean.
cv_rmse <- function(data, folds, fitter, response = "log_price") {
  errs <- vapply(sort(unique(folds)), function(k) {
    train <- data[folds != k, , drop = FALSE]
    test <- data[folds == k, , drop = FALSE]
    predict_fun <- fitter(train)
    rmse(test[[response]], predict_fun(test))
  }, numeric(1))
  list(fold_rmse = errs, rmse = mean(errs))
}

# Choose a hyperparameter by CV. `make_fitter(value)` returns a fitter for one
# grid value. Returns the best value and the full CV curve.
cv_tune <- function(data, folds, grid, make_fitter, response = "log_price") {
  curve <- vapply(grid, function(g) {
    cv_rmse(data, folds, make_fitter(g), response)$rmse
  }, numeric(1))
  list(best = grid[which.min(curve)],
       curve = data.frame(value = grid, cv_rmse = curve))
}
