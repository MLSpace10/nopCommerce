# Scenario data

Task-specific `apply.sql`, `reset.sql`, and `verify.sql` files are added only with an accepted, reproducible task baseline. Manual database corruption is not a supported workflow.

Run them only through the guarded entrypoint:

```powershell
./training/scripts/scenario.ps1 apply TRN-###
./training/scripts/scenario.ps1 verify TRN-###
./training/scripts/scenario.ps1 reset TRN-###
```

The runner accepts only `TRN-###`, imports the explicit lab configuration, and refuses any database other than `CommerceEngineeringLab`.
