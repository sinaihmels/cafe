# Cafe

Cafe is now a single canonical Godot project.

The current playable slice is still a small bakery run, but the underlying systems now exist for the full game direction:

- title and routed screen flow
- cafe hub
- decoration placement
- permanent shop upgrades
- equipment install flow
- dough selection
- encounter kitchen simulation with prep, oven, and table zones
- multi-customer encounters
- reward screen
- run shop
- boss intro
- summary
- meta-profile save/load
- generic buffs and statuses

## Boot Flow

The project boots from `res://scenes/app/app.tscn`.

The app scene creates:

- `SessionService` as the canonical runtime and screen state authority
- `SaveService` for persistent meta-profile save/load
- `EventBus` for runtime signals
- `EffectQueueService` for ordered card effect resolution
- `AppController` for input orchestration and routing
- `AppView` for the full UI shell

## Content And Assets

Canonical authored content now lives in top-level folders under `res://data/`:

- `cards`
- `customers`
- `ingredients`
- `recipes`
- `doughs`
- `equipment`
- `decorations`
- `shop_upgrades`
- `buffs`
- `statuses`
- `rewards`
- `offers`

Placeholder art is still used from `res://assets/demo/`.
The current build intentionally keeps using those placeholders and fallback rules while systems expand.

## Tests

Canonical smoke tests live in `res://tests/game/`.

Examples:

- `godot --headless --script res://tests/game/test_meta_profile_service.gd`
- `godot --headless --script res://tests/game/test_run_flow.gd`
- `godot --headless --script res://tests/game/test_modifier_flow.gd`


## Design Docs

- `GameConcept.md`: long-term game vision
- `ARCHITECTURE.md`: canonical current runtime structure
- `ROADMAP.md`: expansion plan from this foundation
