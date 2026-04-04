# Tests

Canonical gameplay smoke tests live under `res://tests/game/`.

Current smoke targets:

- `test_meta_profile_service.gd`
- `test_run_flow.gd`
- `test_modifier_flow.gd`
- `test_pastry_refactor.gd`
- `test_proofing_flow.gd`
- `test_serve_flow.gd`
- `test_tag_demand_flow.gd`

These scripts cover the single-project runtime foundation:

- profile creation, purchases, and decoration placement
- screen routing from encounter to reward, shop, boss intro, and summary
- run buffs plus persistent upgrade ownership
- pastry-seed encounter flow, proofing, baking, plating, and serving
- card taxonomy migration plus interaction/technique smoke coverage
- state-aware customer demand scoring

Run each with a headless Godot command, for example:

`godot --headless --script res://tests/game/test_run_flow.gd`

This workspace does not currently have a `godot` executable on PATH, so these tests were added but not executed in this session.
