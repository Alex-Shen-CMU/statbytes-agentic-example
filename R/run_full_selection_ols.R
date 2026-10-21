# OLS full-selection sweep driver. Run from the repo root.
#
#   Rscript R/run_full_selection_ols.R n_models
#       Print the number of candidate models (for sizing a job array).
#   Rscript R/run_full_selection_ols.R fit <id> [out_root]
#       Fit model <id> and write <out_root>/full_selection/ols_models/model_<id>.csv
#   Rscript R/run_full_selection_ols.R combine [out_root]
#       Combine per-model files into <out_root>/full_selection/ols.csv
#
# out_root defaults to "output".

source("R/full_selection.R")

args <- commandArgs(trailingOnly = TRUE)
cmd <- args[1]

if (identical(cmd, "n_models")) {
  cat(nrow(ols_model_grid()), "\n")

} else if (identical(cmd, "fit")) {
  id <- as.integer(args[2])
  out_root <- if (length(args) >= 3) args[3] else "output"
  stopifnot(!is.na(id), id >= 1, id <= nrow(ols_model_grid()))
  model_dir <- file.path(out_root, "full_selection", "ols_models")
  dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)
  res <- run_ols_model(id)
  print(res, row.names = FALSE, digits = 4)
  write.csv(res, file.path(model_dir, sprintf("model_%03d.csv", id)),
            row.names = FALSE)

} else if (identical(cmd, "combine")) {
  out_root <- if (length(args) >= 2) args[2] else "output"
  sel_dir <- file.path(out_root, "full_selection")
  files <- list.files(file.path(sel_dir, "ols_models"), "^model_\\d+\\.csv$",
                      full.names = TRUE)
  res <- combine_ols_results(files)
  # Output table: RMSE, then one in/out column per predictor.
  write.csv(res[, setdiff(names(res), "model")], file.path(sel_dir, "ols.csv"),
            row.names = FALSE)
  print(head(res, 10), row.names = FALSE, digits = 4)

} else {
  stop("usage: run_full_selection_ols.R {n_models | fit <id> [out_root] | ",
       "combine [out_root]}")
}
