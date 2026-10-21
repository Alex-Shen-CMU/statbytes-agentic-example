# Clean the data, compare OLS / LASSO / spline models by nested cross-validation,
# and fit final models on the full data.
#
# Run from the repo root:  Rscript R/run_analysis.R

source("R/clean_data.R")
source("R/cv.R")
source("R/models.R")

K_OUTER <- 5
K_INNER <- 5
SEED <- 1

cars <- clean_cars()
cat(sprintf("Cleaned data: %d cars, %d brands\n\n", nrow(cars),
            nlevels(cars$brand)))

fitters <- list(
  ols    = fit_ols,
  lasso  = function(tr) fit_elasticnet(tr, alphas = 1, K = K_INNER,
                                       seed = SEED),
  spline = function(tr) fit_spline(tr, K = K_INNER, seed = SEED)
)

# Nested CV: hyperparameters are re-tuned inside each outer training fold, so
# the outer RMSE is an honest estimate for each full model-fitting procedure.
outer_folds <- make_folds(nrow(cars), K_OUTER, strata = cars$brand, seed = SEED)
results <- lapply(fitters, function(f) cv_rmse(cars, outer_folds, f))

summary_tbl <- data.frame(
  model = names(results),
  cv_rmse = vapply(results, `[[`, numeric(1), "rmse"),
  cv_rmse_se = vapply(results, function(r) sd(r$fold_rmse) / sqrt(K_OUTER),
                      numeric(1))
)
cat("Nested CV RMSE on log price:\n")
print(summary_tbl, row.names = FALSE, digits = 3)

# Final fits on all data.
final <- lapply(fitters, function(f) f(cars))

lasso_tuning <- attr(final$lasso, "tuning")
cat(sprintf("\nLASSO: lambda = %.4g\n", lasso_tuning$lambda))
lasso_coef <- as.matrix(coef(attr(final$lasso, "fit"), s = "lambda.min"))
cat(sprintf("  %d of %d coefficients nonzero\n", sum(lasso_coef != 0) - 1,
            nrow(lasso_coef) - 1))

spline_tuning <- attr(final$spline, "tuning")
cat(sprintf("\nSpline df chosen by CV: %d\n", spline_tuning$df))
print(spline_tuning$df_curve, row.names = FALSE, digits = 3)

dir.create("output", showWarnings = FALSE)
write.csv(summary_tbl, file.path("output", "cv_results.csv"), row.names = FALSE)
write.csv(cars, file.path("output", "cars_clean.csv"), row.names = FALSE)

# Residual plots: in-sample residuals of each final fit against each predictor
# on the scale it enters the model (boxplots for factors).
plot_vars <- c(continuous_vars, other_vars)
feats <- add_features(cars)
for (m in names(final)) {
  plot_dir <- file.path("output", "residual_plots", m)
  dir.create(plot_dir, recursive = TRUE, showWarnings = FALSE)
  resid <- cars$log_price - final[[m]](cars)
  for (v in plot_vars) {
    png(file.path(plot_dir, paste0(v, ".png")), width = 700, height = 500)
    x <- feats[[v]]
    main <- sprintf("%s: residuals vs %s", m, v)
    if (is.factor(x)) {
      par(mar = c(10, 4, 4, 1))  # room for rotated level labels
      boxplot(resid ~ x, main = main, xlab = "", ylab = "Residual (log price)",
              las = 2)
    } else {
      plot(x, resid, main = main, xlab = v, ylab = "Residual (log price)",
           pch = 16, col = adjustcolor("black", 0.4))
      lines(lowess(x, resid), col = "red", lwd = 2)
    }
    abline(h = 0, lty = 2)
    dev.off()
  }
}
cat(sprintf("\nResidual plots written to %s\n",
            file.path("output", "residual_plots")))
