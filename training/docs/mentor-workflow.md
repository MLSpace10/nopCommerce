# Mentor workflow

The student repository contains only platform checkpoints, `task/TRN-###-baseline` branches, tickets, deterministic scenarios, visible tests, and acceptance criteria. A separately access-controlled mentor repository contains `solution/TRN-###`, root-cause notes, flow maps, reference diffs, hidden tests, three hint levels, and review checklists.

For each task, the mentor:

1. Authors and validates the student skeleton and scenario without exposing the solution.
2. Confirms build success before the fix unless build failure is the intended defect.
3. Repeats reset and reproduction three times and records matching evidence.
4. Confirms the visible acceptance test fails for the intended reason.
5. Implements and verifies the reference solution only in the mentor repository.
6. Runs narrow, integration, broader, HTTP, database, and related-read checks.
7. Reviews minimality, compatibility, edge cases, and communication using the 100-point rubric.

Mentor automation exposes only the command `mentor-verify TRN-###`; it must not copy hidden artifacts or solution refs into the student checkout.
