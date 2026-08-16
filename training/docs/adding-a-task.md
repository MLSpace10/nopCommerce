# Adding a task

Run the skeleton generator only while authoring a future task phase:

```powershell
./training/scripts/new-task.ps1 -Id TRN-999 -Title "Synthetic example" -Type bug
```

The generator creates the student directory and `apply.sql`, `reset.sql`, and `verify.sql` placeholders. Replace every placeholder; never use a throwing template as a baseline. Complete the ticket sections without naming the defective file, exact root cause, exact SQL, hidden assertion, or original upstream fix.

The manifest must conform to `training/task-framework/manifest.schema.json`. Branch names are `training/platform`, `task/TRN-###-baseline`, and mentor-only `solution/TRN-###`. The scenario ID and directory must match the manifest ID. Visible verification belongs under the student task; hidden verification is referenced only as `mentor-verify TRN-###`.

Before accepting a baseline:

1. Run `./training/scripts/verify-task-framework.ps1`.
2. Run reset → reproduce three times and compare the observed HTTP/database evidence.
3. Confirm the visible test fails for the intended reason.
4. Verify the reference fix in the separate mentor repository.
5. Run all task quality gates from the original prompt and review the complete diff.

Do not create a branch, commit, push, or publish from the generator; those remain explicit owner actions.
