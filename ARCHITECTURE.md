# Cozy Deckbuilder Architecture

This scaffold follows the project's non-negotiable rules:

- Data is separate from runtime instances and UI.
- Gameplay changes flow through an effect queue.
- Systems communicate through an event bus.
- Turn flow is state-machine based.
- State lives in dedicated resource objects.

## Current Boot Flow

`App` scene creates:

- `SessionService` for authoritative state
- `EventBus` for cross-system signals
- `EffectQueueService` for sequential resolution
- `GameplayController` for orchestration
- `GameplayView` for rendering and input only

## Naming Rules

- `*_def`: immutable authored content
- `*_instance`: mutable runtime objects
- `*_state`: source-of-truth state resources
- `*_controller`: orchestration
- `*_service`: shared systems
- `*_view`: rendering and user input
- `*_effect`: atomic state changes

## Suggested Next Steps

1. Add item and recipe definitions under `res://data/`.
2. Expand `BaseEffect` subclasses for board movement, baking, and serving.
3. Introduce customer spawning and patience resolution in `GameplayController`.
4. Move sample starter deck setup into a proper run-generation pipeline.
5. Add automated tests around effect ordering and state transitions.
