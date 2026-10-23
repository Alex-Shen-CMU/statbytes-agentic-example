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

### OLS full selection

`R/run_full_selection_ols.R` fits all 2^8 = 256 OLS subsets (brand always in;
the fuel indicators enter or leave together) and ranks them by 5-fold CV RMSE
on the same brand-stratified folds as above. Each model is fitted independently,
e.g. as one slurm array task:

```sh
Rscript R/run_full_selection_ols.R fit <id>   # id in 1..256
Rscript R/run_full_selection_ols.R combine    # -> output/full_selection/ols.csv
```

`ols.csv` has one row per model (best first): `rmse`, then one TRUE/FALSE
column per optional predictor.

## Trying out the Claude Code workflow

This repo is set up so that Claude Code picks up tasks from GitHub issues and
answers with a branch and pull request (see `CLAUDE.md` for the full set of
conventions it follows).

### 1. Fork this repo

If you want to tinker with this codebase, **fork it first** and work on your
fork. The workflow opens branches and pull requests, and those should land on
your copy, not on this one.

### 2. Install the GitHub MCP server

Claude uses the GitHub MCP server to read issues, post comments and open PRs.
The server is already declared in `.mcp.json`, which reads your token from the
`GITHUB_PAT` environment variable rather than storing it:

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": { "Authorization": "Bearer ${GITHUB_PAT}" }
    }
  }
}
```

1. Create a [GitHub personal access token](https://github.com/settings/personal-access-tokens)
   with access to your fork (read/write on issues, pull requests and contents).
2. Put the token in `.claude/settings.local.json` (git-ignored, so it never gets
   committed), and enable the server:

   ```json
   {
     "enabledMcpjsonServers": ["github"],
     "env": { "GITHUB_PAT": "<your token>" }
   }
   ```

3. Run `/mcp` inside Claude Code to check that `github` is connected.

Do **not** add the server with something like
`claude mcp add ... -H "Authorization: Bearer ghp_..."`: that puts the token in
plaintext in your shell history and in Claude's config file.

### 3. General workflow

1. Fork the repo, then clone your fork locally.
2. On your fork's GitHub page, describe a task in a new issue.
3. In your local clone, launch `claude` (optionally inside a `tmux` session, so
   it keeps running after you disconnect).
4. Tell Claude: `work on issue <number>`.
5. Wait for any clarifying questions and answer them. Then you can leave and come
   back to a pull request, with progress updates posted as comments on the issue.

Label an issue `test-run` to have Claude do a dry run: it works on a local
`test-` branch, writes outputs to `test_output/`, and does not push or open a PR.
