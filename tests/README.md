# Tests

Put gameplay-focused tests here as systems stabilize.

Recommended early targets:

- effect queue ordering
- card validation and play flow
- customer patience changes
- end-of-turn transitions
- save/load reconstruction of state resources

## Demo v0 Tests

The clean-slate demo rewrite includes script-driven smoke tests in `res://tests/demo/`:

- `test_demand_matcher.gd`
- `test_card_engine.gd`
- `test_customer_ai.gd`
- `test_integration_flow.gd`

Run each with a headless Godot command, for example:

`godot --headless --script res://tests/demo/test_demand_matcher.gd`
