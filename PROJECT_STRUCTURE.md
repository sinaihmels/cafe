# Project Structure Guide

This document explains the current Godot project layout, what each folder is for, and where new files should go.

The project is intentionally organized around these rules:

- Data is authored separately from runtime state.
- UI does not contain gameplay logic.
- Controllers and services orchestrate behavior.
- State changes flow through effects.
- Shared reactions flow through events.

## Mental Model

Use this model whenever you add a new feature:

`Definition (data) -> Instance/state (runtime) -> Controller/service (logic) -> View (rendering only)`

Examples:

- Card data: `CardDef`
- Runtime card copy: `CardInstance`
- Card play flow: `GameplayController` + `EffectQueueService`
- Card rendering: `GameplayView`

## Top-Level Folders

### `res://assets/`

Put raw game assets here.

Examples:

- textures
- icons
- sprites
- audio
- fonts

Use this folder for imported visual/audio content only, not gameplay logic.

### `res://data/`

Put authored game content here as Godot resources (`.tres` / `.res`).

This is the home for immutable definitions.

Current subfolders:

- `res://data/cards/`: card definitions
- `res://data/ingredients/`: ingredient definitions
- `res://data/customers/`: customer definitions
- `res://data/recipes/`: recipe definitions
- `res://data/statuses/`: status definitions
- `res://data/relics/`: relic definitions
- `res://data/events/`: event definitions

What goes here:

- cards the player can draw/play
- ingredients and baked goods
- recipes and transformations
- customer templates
- relics and passive modifiers
- authored narrative/event content

Examples:

- Add a new card: `res://data/cards/my_new_card.tres`
- Add a new customer: `res://data/customers/impatient_critic.tres`
- Add a recipe: `res://data/recipes/berry_tart.tres`

### `res://scenes/`

Put Godot scenes here.

Scenes are visual composition and wiring, not core game rules.

Current subfolders:

- `res://scenes/app/`: app boot/root scenes
- `res://scenes/gameplay/`: gameplay board scenes
- `res://scenes/ui/`: UI scenes and widgets
- `res://scenes/map/`: run map scenes
- `res://scenes/reward/`: reward/upgrade screens

What goes here:

- the root app scene
- gameplay layout scenes
- reusable UI widgets
- reward screens
- map navigation screens

Examples:

- Main boot scene: `res://scenes/app/app.tscn`
- Hand/card UI widgets later: `res://scenes/ui/card_view.tscn`
- Reward screen later: `res://scenes/reward/reward_screen.tscn`

### `res://scripts/`

Put GDScript code here, grouped by responsibility.

Current subfolders:

- `res://scripts/app/`: app bootstrap/root scripts
- `res://scripts/core/`: enums and source-of-truth state resources
- `res://scripts/combat/`: turn flow and gameplay orchestration
- `res://scripts/cards/`: card definition/runtime classes
- `res://scripts/effects/`: atomic effects and effect context
- `res://scripts/systems/`: shared services like session/event/effect queue
- `res://scripts/entities/`: customers, items, and similar game entities
- `res://scripts/map/`: map/run-navigation logic
- `res://scripts/progression/`: rewards, unlocks, meta progression
- `res://scripts/ui/`: view-only UI scripts

### `res://tests/`

Put automated tests and test helpers here as the systems solidify.

Good first tests:

- effect queue ordering
- card validation
- end turn transitions
- customer patience changes
- save/load serialization

## Current Core Files

### App Boot

- [project.godot](/C:/Users/Sina/Documents/cafe/project.godot)
  Sets the main scene.
- [app.tscn](/C:/Users/Sina/Documents/cafe/scenes/app/app.tscn)
  Root scene that wires services, controller, and UI together.
- [app_controller.gd](/C:/Users/Sina/Documents/cafe/scripts/app/app_controller.gd)
  Root node script for the app scene.

### Core State

These files are the single source of truth for runtime state.

- [game_enums.gd](/C:/Users/Sina/Documents/cafe/scripts/core/game_enums.gd)
  Shared enums for turn and run phases.
- [run_state.gd](/C:/Users/Sina/Documents/cafe/scripts/core/run_state.gd)
  Run-level state like current day and phase.
- [combat_state.gd](/C:/Users/Sina/Documents/cafe/scripts/core/combat_state.gd)
  Turn-level state machine and active customer tracking.
- [player_state.gd](/C:/Users/Sina/Documents/cafe/scripts/core/player_state.gd)
  Energy, reputation, chaos.
- [cafe_state.gd](/C:/Users/Sina/Documents/cafe/scripts/core/cafe_state.gd)
  Zone capacities and zone contents.
- [deck_state.gd](/C:/Users/Sina/Documents/cafe/scripts/core/deck_state.gd)
  Draw pile, discard pile, and hand.

When you need new global gameplay state, add it here first instead of storing it on scenes.

### Card Model

- [card_def.gd](/C:/Users/Sina/Documents/cafe/scripts/cards/card_def.gd)
  Immutable card definition resource.
- [card_instance.gd](/C:/Users/Sina/Documents/cafe/scripts/cards/card_instance.gd)
  Mutable runtime card copy.

If you add card metadata, add it to `CardDef`.
If you add temporary combat-only card changes, add them to `CardInstance`.

### Effects

- [base_effect.gd](/C:/Users/Sina/Documents/cafe/scripts/effects/base_effect.gd)
  Base class for all atomic effects.
- [effect_context.gd](/C:/Users/Sina/Documents/cafe/scripts/effects/effect_context.gd)
  Runtime context passed into effect execution.
- [gain_energy_effect.gd](/C:/Users/Sina/Documents/cafe/scripts/effects/gain_energy_effect.gd)
- [draw_cards_effect.gd](/C:/Users/Sina/Documents/cafe/scripts/effects/draw_cards_effect.gd)
- [add_chaos_effect.gd](/C:/Users/Sina/Documents/cafe/scripts/effects/add_chaos_effect.gd)

Whenever a card, relic, status, or customer changes gameplay state, prefer adding a new effect here.

Examples of future effect files:

- `res://scripts/effects/add_ingredient_effect.gd`
- `res://scripts/effects/move_item_effect.gd`
- `res://scripts/effects/bake_effect.gd`
- `res://scripts/effects/serve_customer_effect.gd`

### Systems and Orchestration

- [event_bus.gd](/C:/Users/Sina/Documents/cafe/scripts/systems/event_bus.gd)
  Central signal hub for cross-system events.
- [effect_queue_service.gd](/C:/Users/Sina/Documents/cafe/scripts/systems/effect_queue_service.gd)
  Sequential effect resolution.
- [session_service.gd](/C:/Users/Sina/Documents/cafe/scripts/systems/session_service.gd)
  Owns the authoritative run/combat/player/cafe/deck state.
- [gameplay_controller.gd](/C:/Users/Sina/Documents/cafe/scripts/combat/gameplay_controller.gd)
  Coordinates turns, card play, energy spending, and view refresh.

If a feature coordinates multiple systems, it usually belongs in a controller or service, not in a view.

### UI

- [gameplay_view.tscn](/C:/Users/Sina/Documents/cafe/scenes/ui/gameplay_view.tscn)
  Current gameplay shell.
- [gameplay_view.gd](/C:/Users/Sina/Documents/cafe/scripts/ui/gameplay_view.gd)
  View-only script that renders state and emits input signals.

Add future UI scripts/scenes here:

- card widgets
- customer panels
- zone panels
- reward choices
- map nodes

## Where To Put New Files

### New Cards

Put authored card resources in:

- `res://data/cards/`

Use scripts:

- `res://scripts/cards/card_def.gd`
- `res://scripts/cards/card_instance.gd`

If a card needs a new gameplay action, create a new effect in:

- `res://scripts/effects/`

Typical workflow:

1. Create a new effect script if needed.
2. Create a `.tres` card resource in `res://data/cards/`.
3. Reference the effect resource(s) from the card.
4. Make sure the runtime deck generation includes that card.

### New Ingredients or Baked Items

Put authored definitions in:

- `res://data/ingredients/`

If you later distinguish ingredients from final baked goods, you can either:

- keep both under `ingredients/` for simplicity, or
- add a dedicated `items/` folder later if the content grows

Use runtime entity scripts in:

- `res://scripts/entities/item_def.gd`
- `res://scripts/entities/item_instance.gd`

### New Customers

Put customer definitions in:

- `res://data/customers/`

Use scripts:

- `res://scripts/entities/customer_def.gd`
- `res://scripts/entities/customer_instance.gd`

Customer spawn/turn/reaction logic should go in:

- `res://scripts/combat/`
- or `res://scripts/systems/`

depending on whether it is turn-flow-specific or shared.

### New Recipes

Put recipe data in:

- `res://data/recipes/`

Recipe execution should usually become one or more effects in:

- `res://scripts/effects/`

Avoid embedding recipe logic directly in UI or in the recipe resource itself.

### New Statuses or Relics

Put authored definitions in:

- `res://data/statuses/`
- `res://data/relics/`

Hook their runtime reactions through:

- `res://scripts/systems/event_bus.gd`
- effect generation
- controllers/services that subscribe to events

The pattern should be:

- status/relic hears event
- status/relic generates effect
- effect queue resolves it

### New Screens

Put scenes in:

- `res://scenes/ui/`
- `res://scenes/reward/`
- `res://scenes/map/`
- `res://scenes/gameplay/`

Put their scripts in matching script folders:

- `res://scripts/ui/`
- `res://scripts/progression/`
- `res://scripts/map/`
- `res://scripts/combat/`

## Naming Rules

Use these suffixes consistently:

- `*_def`: immutable authored content
- `*_instance`: mutable runtime object
- `*_state`: source-of-truth runtime state
- `*_controller`: orchestration and decision flow
- `*_service`: shared logic/system access
- `*_view`: rendering and input only
- `*_effect`: atomic gameplay action

Examples:

- `card_def.gd`
- `customer_instance.gd`
- `run_state.gd`
- `reward_controller.gd`
- `save_service.gd`
- `card_view.gd`
- `serve_customer_effect.gd`

## Dependency Direction

Keep dependencies moving in this direction:

`View -> Controller -> State -> Effects`

More concretely:

- Views ask controllers to do things.
- Controllers validate actions and build effect contexts.
- Effects mutate state.
- Events notify other systems.
- Views re-render from state.

Avoid:

- view mutating state directly
- effect reading UI nodes
- node-to-node gameplay dependencies
- one giant singleton that owns everything

## Feature Checklist

When adding a new gameplay feature, use this checklist:

1. Define the authored data shape if needed.
2. Add or extend runtime state if needed.
3. Add atomic effects for state changes.
4. Update controller/service logic to validate and enqueue effects.
5. Emit/listen to events where reactions are needed.
6. Render the result in a view.
7. Add tests once behavior stabilizes.

## Current Gaps

The scaffold is ready, but these areas are still starter-level:

- customer turn logic
- zone item movement
- baking transformations
- serving and scoring
- reward flow
- map progression
- save/load

Those systems should be added without breaking the structure above.
