# Vertical Slice Logic

This document maps the example run to the current project architecture and lists the gameplay logic we need to implement to recreate it.

## Target Experience

The vertical slice is a small roguelite deckbuilder about running a cafe:

- Play ingredient and action cards during a turn.
- Build items in `Prep`.
- Move dough into the `Oven` and wait 1 turn for baking.
- Decorate or serve finished items.
- Match customer requests for speed, sweetness, and quality.
- Gain or lose reputation based on the outcome.

## Core State We Need

The current state resources are the right place to store this.

### `PlayerState`

Already has:

- energy
- reputation
- chaos

Still needed:

- optional reward currency if rewards are not free picks

### `CafeState`

Already has:

- prep space
- oven
- serving table

Needs richer item storage:

- prep items should become full `ItemInstance` records, not just string IDs
- oven slots need a per-slot bake timer
- table items need enough metadata to validate customer requests

Suggested additions:

- `prep_items: Array[ItemInstance]`
- `oven_slots: Array[Dictionary]` with `item` and `remaining_turns`
- `table_items: Array[ItemInstance]`

### `CombatState`

Already has turn number and turn state.

Needs:

- active customers as runtime instances
- optional request queue for the day
- day loss / success resolution flags

### `RunState`

Already has day number and run phase.

Needs:

- simple day progression
- reward/event sequencing
- unlock tracking for the run

## Authored Data We Need

### Cards

Ingredient cards:

- Flour
- Butter
- Sugar
- Chocolate
- Cinnamon

Action cards:

- Mix
- Bake
- Decorate
- Improvise
- Flash Bake
- Prep Ahead
- Clean Up

### Items

Base:

- Flour
- Butter
- Sugar
- Chocolate
- Cinnamon

Intermediate:

- Dough
- Sweet Dough
- Chocolate Dough

Baked:

- Pastry
- Sweet Pastry
- Chocolate Pastry

High-quality:

- Decorated Pastry
- Perfect Sweet Pastry

Failure:

- Burned

### Recipes

Recipe definitions should drive transformations instead of hardcoding them in UI:

- Flour + Butter -> Dough
- Dough + Sugar -> Sweet Dough
- Dough + Chocolate -> Chocolate Dough
- Dough baked -> Pastry
- Sweet Dough baked -> Sweet Pastry
- Chocolate Dough baked -> Chocolate Pastry
- Pastry decorated -> Decorated Pastry
- Sweet Pastry decorated -> Perfect Sweet Pastry

### Customers

At minimum we need authored requests for:

- wants something sweet
- wants anything but fast
- wants high quality
- boss critic who needs sweet + decorated

## Runtime Systems We Need

## 1. Item Runtime Model

`ItemInstance` needs enough state to answer gameplay and scoring questions.

Suggested fields:

- `item_id`
- `display_name`
- `tags`
- `quality`
- `zone`
- `baked: bool`
- `decorated: bool`
- `burned: bool`
- `created_turn`
- `steps_used`

This lets us score "fast", "sweet", "high quality", and "decorated" requests.

## 2. Target Selection

The current UI can only click a card in hand. The vertical slice needs target selection for:

- choosing 2 prep items for `Mix`
- choosing 1 prep item for `Bake`
- choosing 1 baked item for `Decorate`
- choosing 1 item to `Serve`
- choosing 1 item to `Clean Up`

Needed flow:

1. player clicks a card
2. controller checks targeting rules
3. view enters selection mode
4. player clicks valid items or customer targets
5. controller builds `EffectContext.targets`
6. effect queue resolves

## 3. New Effects

The vertical slice should express state changes as effects.

Needed effects:

- `SpawnItemEffect`
- `MixItemsEffect`
- `MoveItemToOvenEffect`
- `AdvanceOvenEffect`
- `DecorateItemEffect`
- `ServeItemEffect`
- `DrawCardsIfPrepEmptyEffect`
- `FlashBakeEffect`
- `SpawnRandomBasicIngredientEffect`
- `RemoveItemEffect`
- `GainReputationEffect`
- `LoseReputationEffect`

## 4. Oven Resolution

At end of each player turn or start of the next turn:

1. decrement timers on all occupied oven slots
2. when a timer reaches 0, transform the item to its baked result
3. move it back to prep or table depending on the design

To match the sample run cleanly:

- `Bake` consumes 1 energy
- the item spends exactly 1 full turn in the oven
- at the start of the next player turn it is ready

## 5. Customer Request Validation

We need a request matcher that scores served items against customer rules.

Examples:

- Sweet request: item must have `sweet`
- Fast request: any baked item works, but fewer preparation steps gives bonus
- High quality request: decorated or quality >= 1
- Critic request: item must have both `sweet` and `decorated`

Suggested result tiers:

- wrong item -> reputation penalty
- valid basic item -> +1 reputation
- good match -> +2 reputation
- perfect match -> +3 reputation

## 6. Day Flow

To reproduce the sample run we need a fixed scripted day flow first.

### Day 1

- spawn 1 sweet customer
- reward choice after success

### Day 2

- spawn 2 customers: sweet and fast
- then trigger event node

### Day 3

- spawn 3 customers: sweet, high quality, fast

### Final Day

- spawn critic boss request

This can be authored as a simple scripted day list before procedural generation exists.

## 7. Reward and Event Flow

After a day ends:

- enter `RunPhase.REWARD`
- offer 3 reward options
- add picked card or upgrade to deck/state

For the event:

- enter `RunPhase.EVENT`
- show choice UI
- resolve deterministic or weighted outcome
- grant Cinnamon on the improvise branch

## 8. Failure Conditions

To match the run summary:

- run fails if reputation reaches 0
- poor serves or timeouts reduce reputation
- blocked oven/table capacity can indirectly cause failed orders

## Minimal Delivery Order

To make the slice playable quickly:

1. add item and recipe authored data
2. add ingredient card effects that spawn prep items
3. add target selection and item buttons in the view
4. implement `Mix`, `Bake`, `Decorate`, `Serve`
5. implement oven timers
6. implement customer requests and scoring
7. implement scripted day/reward/event flow
8. add tests for recipe resolution, oven timing, and customer scoring

## What The Current Project Already Has

The current scaffold already gives us:

- authoritative state ownership in `SessionService`
- turn orchestration in `GameplayController`
- sequential effect resolution in `EffectQueueService`
- view-only rendering in `GameplayView`

So the remaining work is mostly filling in domain-specific state, effects, and authored content rather than rewriting the architecture.
