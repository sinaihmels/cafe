# Canonical Architecture

## Goal

The repo now contains one project only.

The current playable content is still a small demo slice, but it runs on the same canonical systems that are meant to support the eventual larger game.

## Core Runtime

### App Layer

`AppController` orchestrates user input and screen transitions.

`AppView` renders all routed screens:

- Title
- Cafe Hub
- Decoration
- Dough Select
- Encounter
- Reward
- Run Shop
- Boss Intro
- Summary

### Runtime Authority

`SessionService` is the main gameplay authority.
It owns and mutates:

- `RunState`
- `CombatState`
- `PlayerState`
- `CafeState`
- `DeckState`

It also owns the canonical content loader and exposes the screen/routing API used by the controller and view.

### Persistence

`SaveService` stores permanent progression in `user://meta_profile.json`.

Persistent state includes:

- meta currency
- unlocked doughs
- unlocked cards
- unlocked customers
- owned equipment
- equipped equipment
- owned decorations
- decoration layout
- purchased shop upgrades
- unlocked buffs and statuses
- run count and best run day

Run-only state is intentionally separate and rebuilt when a run starts.

### Effect And Modifier Systems

Cards remain data-authored and effect-driven.
Card effects resolve through `EffectQueueService`.

The generic modifier layer supports:

- player buffs
- customer statuses
- item statuses
- equipment passives
- shop-upgrade passives
- dough passives

Supported modifier hooks currently include:

- on apply
- turn start
- turn end
- card played
- customer served
- item baked
- on expire

### Encounter Model

The encounter model now uses final-game-capable kitchen state instead of the old shared dish abstraction.

Canonical encounter zones:

- prep area
- oven slots with timers
- serving table

Canonical runtime actors:

- multiple active customers
- mutable item instances
- mutable customer instances
- mutable modifier instances

## Content Organization

### Authored Definitions

Immutable authored content is stored in resource defs:

- `CardDef`
- `CustomerDef`
- `ItemDef`
- `RecipeDef`
- `DoughDef`
- `EquipmentDef`
- `DecorationDef`
- `ShopUpgradeDef`
- `RewardDef`
- `CardOfferDef`
- `BuffDef`
- `StatusDef`

### Runtime Instances And State

Mutable runtime data is stored in:

- `CardInstance`
- `CustomerInstance`
- `ItemInstance`
- `ModifierInstance`
- state resources under `scripts/core/`

## Screen Flow

Current canonical flow:

`Title -> Cafe Hub -> Dough Select -> Encounter -> Reward -> Encounter -> Run Shop -> Encounter -> Boss Intro -> Encounter -> Summary -> Cafe Hub`

The cafe hub remains outside encounters and is where permanent management happens.

## Assets

The build keeps using placeholder art from `res://assets/demo/`.
No new screen depends on custom final art to function.
The placeholder policy is deliberate for this phase.
