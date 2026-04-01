# Demo v0 Architecture

This project now runs on a clean-slate demo architecture focused on:

- Sweet Dough only
- 5 encounters + final boss encounter
- Mana + Stress core resources
- In-run progression with rewards + shops
- Tag-based dish creation and customer matching

## Core Runtime Systems

- `RunDirector`: phase orchestration and top-level state transitions.
- `EncounterDirector`: per-encounter loop, player actions, serve resolution.
- `CardEngine`: card play validation, mana spending, effect resolution, deck flow.
- `FoodComposer`: dish tags/quality and dough passive handling.
- `DemandMatcher`: dish-to-demand scoring and result tiers.
- `CustomerAI`: end-turn patience pressure and timeout penalties.
- `ProgressionDirector`: rewards, shops, equipment application, and run scaling.

## Data + State Model

- Resource definitions under `res://scripts/demo/data/` and `res://data/demo/`:
  - `DemoDoughDef`, `DemoCardDef`, `DemoDemandRule`, `DemoCustomerDef`
  - `DemoEquipmentDef`, `DemoRewardDef`, `DemoEncounterDef`
- Runtime state:
  - `DemoRunState`, `DemoPlayerState`, `DemoEncounterState`
  - `DemoDeckState`, `DemoFoodState`
  - `DemoCardInstance`, `DemoCustomerInstance`

## Flow

`DOUGH_SELECT -> ENCOUNTER -> REWARD/SHOP -> ... -> BOSS -> SUMMARY or GAME_OVER`

- Shops appear after encounters 2 and 4.
- Boss intro is an explicit phase before final encounter start.

## Scene Wiring

- Main scene: `res://scenes/app/app.tscn`
- View: `res://scenes/ui/demo_view.tscn`
- Root controller: `res://scripts/demo/run_director.gd`

The UI is intentionally view-only and emits intent signals to `RunDirector`.
