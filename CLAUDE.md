# Project: statbytes-agentic-example
## Cluster
- ssh: `ssh ajshen@wright.hss.cmu.edu` (keys set up)
- cluster runs slurm. Relevant partitions are `all` (low priority, pre-emptible) and `statds` (high priority, low capacity)
- never run heavy jobs on hydra
- do not commit slurm scripts
- unless otherwise specified, sync wright outputs back to local
## Conventions
- tasks are described in github issues (e.g. https://github.com/Alex-Shen-CMU/statbytes-agentic-example/issues/1)
- All updates and summaries should be posted as new comments on the corresponding issue
- one branch + PR per issue. Always make sure you are branching from up-to-date main
- never force-push; never touch main
- Always ask clarifying questions instead of guessing
- If you post a comment on a github issue, do not repeat it in the chat session. Summarize with main points only in the session.
## Test runs
If a github issue is labeled with `test-run`, perform the indicated task but append "test" to the beginning of the branch for changes made under the issue and do not open a PR. Outputs should be routed to `test_outputs/`, which is gitignored. If the job requires slurm jobs on wright, run only a small enough subset to prove that the functionality works. 
