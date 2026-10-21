# Models for log price. Each fit_* function takes a training data frame (from
# clean_cars()) and returns a prediction function function(newdata), with the
# fitted object and chosen hyperparameters attached as attributes.

library(glmnet)
library(splines)

# Skewed positive predictors enter on the log scale; engine_cc and battery_kwh
# are zero for EVs / combustion cars respectively, hence log1p.
add_features <- function(d) {
  d$log_hp <- log(d$horsepower)
  d$log_torque <- log(d$torque)
  d$log1p_cc <- log1p(d$engine_cc)
  d$log1p_kwh <- log1p(d$battery_kwh)
  d
}

continuous_vars <- c("log_hp", "log_torque", "top_speed", "accel_0_100",
                     "log1p_cc")
other_vars <- c("log1p_kwh", "seats", "fuel", "brand")

linear_formula <- function() {
  reformulate(c(continuous_vars, other_vars), response = "log_price")
}

# Natural cubic splines with `df` degrees of freedom on each continuous var.
spline_formula <- function(df) {
  terms <- sprintf("ns(%s, df = %d)", continuous_vars, df)
  reformulate(c(terms, other_vars), response = "log_price")
}

# --- OLS ---------------------------------------------------------------------

fit_ols <- function(train) {
  fit <- lm(linear_formula(), data = add_features(train))
  structure(function(newdata) unname(predict(fit, add_features(newdata))),
            fit = fit)
}

# --- Elastic net (LASSO when alphas = 1) -------------------------------------

# lambda is chosen by cv.glmnet and alpha by an outer loop over `alphas`, both
# using the same folds so the CV errors are comparable across alpha.
fit_elasticnet <- function(train, alphas = c(1, 0.75, 0.5, 0.25), K = 5,
                           seed = NULL) {
  tr <- add_features(train)
  f <- linear_formula()
  x <- model.matrix(f, tr)[, -1]
  foldid <- make_folds(nrow(tr), K, strata = tr$brand, seed = seed)

  cvs <- lapply(alphas, function(a) cv.glmnet(x, tr$log_price, alpha = a,
                                              foldid = foldid))
  cv_err <- vapply(cvs, function(cv) min(cv$cvm), numeric(1))
  best <- which.min(cv_err)
  cv <- cvs[[best]]

  predict_fun <- function(newdata) {
    nd <- add_features(newdata)
    nd$log_price <- 0  # placeholder so model.matrix accepts the formula
    newx <- model.matrix(f, nd)[, -1]
    as.numeric(predict(cv, newx, s = "lambda.min"))
  }
  structure(predict_fun, fit = cv,
            tuning = list(alpha = alphas[best], lambda = cv$lambda.min,
                          alpha_curve = data.frame(alpha = alphas,
                                                   cv_mse = cv_err)))
}

# --- Splines -----------------------------------------------------------------

fit_spline_df <- function(train, df) {
  fit <- lm(spline_formula(df), data = add_features(train))
  structure(function(newdata) unname(predict(fit, add_features(newdata))),
            fit = fit)
}

# Spline df (shared across continuous vars) chosen by K-fold CV.
fit_spline <- function(train, df_grid = 1:8, K = 5, seed = NULL) {
  folds <- make_folds(nrow(train), K, strata = train$brand, seed = seed)
  tuned <- cv_tune(train, folds, df_grid,
                   function(df) function(tr) fit_spline_df(tr, df))
  out <- fit_spline_df(train, tuned$best)
  attr(out, "tuning") <- list(df = tuned$best, df_curve = tuned$curve)
  out
}
