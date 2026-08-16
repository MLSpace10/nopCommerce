# Student workflow

1. Bootstrap the platform from the accepted platform branch.
2. Check out the baseline branch named by the mentor: `task/TRN-###-baseline`.
3. Run `./training/scripts/task.ps1 reset TRN-###`.
4. Run `./training/scripts/task.ps1 reproduce TRN-###` and capture the actual HTTP, log, and database evidence.
5. Trace the existing flow before editing, implement the smallest compatible change, and run `./training/scripts/task.ps1 verify TRN-###`.
6. Run the broader commands required by the ticket plus `git diff --check`, then review the entire diff.

The student report must distinguish verified facts from inference and include root cause, changes, rejected alternatives, exact commands/results, HTTP statuses, database evidence, compatibility risks, and remaining uncertainty. Copyable requests use placeholders instead of credentials.

Students do not fetch, enumerate, or inspect `solution/*` branches, mentor remotes, hidden tests, patches, hints, or mentor notes. The opaque `mentor-verify TRN-###` manifest command is executed only by mentor-controlled automation.
