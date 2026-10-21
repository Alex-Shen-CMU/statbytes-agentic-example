# statbytes-agentic-example

A small example repo showcasing agentic coding driven by GitHub issues.

## Problem: car price prediction

Given a dataset of ~1,200 cars (2025 models) with specifications such as brand,
horsepower, torque, top speed, 0–100 km/h time, engine displacement / battery
capacity, fuel type and seat count (`data/Cars Datasets 2025.csv`), we predict
**log price** using linear models. Prices span roughly $4k to $18M, so modelling
on the log scale makes errors relative rather than absolute.

Models compared (in `R/`):

- **OLS** on main effects
- **LASSO** (`glmnet`, alpha = 1), with lambda chosen by CV. `fit_elasticnet()`
  also supports tuning alpha over a grid, but the base analysis uses pure LASSO
- **Natural splines** on the continuous predictors, with degrees of freedom chosen by CV

Models are compared by nested 5-fold cross-validated RMSE on log price.

## Usage

```sh
Rscript R/run_analysis.R   # run from the repo root; requires glmnet
```

Outputs (`output/cv_results.csv`, `output/cars_clean.csv`, and residual plots
in `output/residual_plots/<model>/<predictor>.png`) are written to the
git-ignored `output/` directory. Residual plots show in-sample residuals of each
final fit against each predictor on its model scale (boxplots for factors).
