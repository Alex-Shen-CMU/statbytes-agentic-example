# Project: statbytes-agentic-example
## Cluster
- ssh: `ssh ajshen@wright.hss.cmu.edu` (keys set up)
- cluster runs slurm. Relevant partitions are `all` (low priority, pre-emptible) and `statds` (high priority, low capacity)
- never run heavy jobs on hydra
- do not commit slurm scripts
## Conventions
- tasks are described in github issues (e.g. https://github.com/Alex-Shen-CMU/statbytes-agentic-example/issues/1)
- All updates and summaries should be posted as new comments on the corresponding issue
- one branch + PR per issue. Always make sure you are branching from up-to-date main
- never force-push; never touch main
- Always ask clarifying questions instead of guessing

