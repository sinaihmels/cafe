# 🍰 Cozy Bakery Deckbuilder – Card System Design

---

# 🎯 Purpose of This Document

This document defines how cards work in the game, including:

- Card types
- Tag system (pastry vs card tags)
- Effect system
- Core gameplay interactions

This is designed to match your Godot `CardDef` structure and scale cleanly as the game grows.

---

# 🧾 Card Definition Structure

Each card is defined using:

```
class_name CardDef
extends Resource

@export var card_id: StringName
@export var display_name: String = ""
@export var art: Texture2D
@export var energy_cost: int = 1
@export var tags: PackedStringArray = []
@export var targeting_rules: String = "none"
@export var effects: Array[BaseEffect] = []
@export_multiline var preview_text: String = ""
```

---

# 🧠 Key Design Principle

👉 **Separate card identity from gameplay outcome**

### Card Tags (CardDef.tags)
Used for:
- Classification
- Synergies
- Deckbuilding rules

Examples:
- "ingredient"
- "process"
- "technique"
- "interaction"
- "utility"

### Pastry Tags (Created via effects)
Used for:
- Customer matching
- Scoring
- Recipe identity

Examples:
- sweet
- savory
- chocolaty
- fruity
- pretty
- luxurious

⚠️ These should NOT live in `CardDef.tags`

---

# 🍞 Card Types

## 🍫 Ingredient Cards

Purpose:
- Add flavor/identity to pastries

Examples:
- Chocolate → sweet, chocolaty, luxurious
- Cheese → savory, salty

Design Rules:
- Usually cost 1–2 energy
- Always add tags
- No complex conditions (keep simple)

---

## 🔥 Process Cards

Purpose:
- Transform pastry state
- Enable baking flow

Examples:
- Bake → moves pastry to oven
- Fold → adds flaky
- Proof → prepares pastry for better results

Design Rules:
- Define the core gameplay loop
- Often interact with pastry state

---

## ✨ Technique Cards

Purpose:
- Enhance or multiply effects

Examples:
- Double Batch
- Perfect Timing

Design Rules:
- Usually affect "next action"
- Should enable combos

---

## 🛡️ Interaction Cards

Purpose:
- Manage customers
- Prevent failure

Examples:
- Mini Cookies → +patience
- Small Talk → delay customer

Design Rules:
- Low cost
- Defensive tools

---

## ☕ Utility Cards

Purpose:
- Resource manipulation
- Flow control

Examples:
- Gain energy
- Serve pastry

---

# 🍽️ Pastry Model

The player builds a **single pastry object** using cards.

The pastry contains:

```
Pastry:
- tags: ["sweet", "flaky", "chocolaty"]
- states: ["proofed", "baked", "warm"]
- in_oven: bool
- turns_in_oven: int
```

---

# 🏷️ Tag System

## Tag Categories

### Flavor Tags
- sweet
- savory
- salty
- fruity
- chocolaty
- tangy

### Texture Tags
- flaky
- sticky
- airy

### Presentation Tags
- pretty
- decorated
- shiny
- luxurious

---

## Tag Design Rules

- Tags are **additive**
- Tags define customer satisfaction
- Tags can stack logically (not numerically)

Example:

Chocolate + Strawberry + Glaze →

sweet + chocolaty + fruity + pretty + shiny

---

# 🔄 State System (Important)

States are NOT regular tags.

They control gameplay logic.

## Core States

### proofed
- Enables better baking outcomes

### baked
- Required before serving most pastries

### burned
- Reduces value or fails requirements

### warm
- Temporary state after baking
- Enables bonus effects

---

## State Rules

- States can expire (e.g. warm)
- States can conflict (baked vs burned)
- States influence effects

---

# 🔥 Oven System

Core mechanic of the game.

## Bake Flow

1. Player uses Bake
2. Pastry enters oven
3. After 1 turn → gains "baked"
4. If left too long → gains "burned"
5. When removed → gains "warm" (temporary)

---

# ⚙️ Effect System

All gameplay logic should live in **effects**, not tags.

---

## Core Effect Types

### 1. AddPastryTagsEffect

Adds flavor/visual tags

Example:
```
AddPastryTagsEffect(["sweet", "chocolaty"])
```

---

### 2. AddPastryStateEffect

Adds states like baked or proofed

```
AddPastryStateEffect("proofed")
```

---

### 3. ConditionalEffect

Runs logic only if conditions are met

Example:
```
If NOT warm → add sticky
```

---

### 4. OvenEffect

Handles baking system

- Queue pastry
- Resolve after turns
- Apply baked/burned

---

### 5. ModifyCustomerPatienceEffect

Used by interaction cards

```
+1 patience
```

---

### 6. DuplicateEffect

Used by combo cards

```
Duplicate next pastry creation
```

---

### 7. ServeEffect

- Delivers pastry
- Compares tags with customer
- Clears pastry

---

# 🧩 Example Card Implementations

## Chocolate

```
tags: ["ingredient"]

Effects:
- AddPastryTags(["sweet", "chocolaty", "luxurious", "pretty"])
```

---

## Bake

```
tags: ["process", "oven"]

Effects:
- Send pastry to oven
- After 1 turn → add baked
- If delayed → add burned
- On exit → add warm
```

---

## Sugar Glaze

```
tags: ["process", "finisher"]

Effects:
- Add sweet, luxurious, shiny, pretty
- If NOT warm → add sticky
```

---

## Mini Cookies

```
tags: ["interaction"]

Effects:
- Increase customer patience by 1
```

---

# ⚖️ Balance Guidelines

## Energy Costs

- 0 cost → utility / weak effects
- 1 cost → standard cards
- 2 cost → strong tags or setup
- 3 cost → powerful finishers

---

## Design Philosophy

- Ingredients = simple
- Processes = structure gameplay
- Techniques = create combos
- Interaction = prevent failure

---

# 🔗 Synergy Examples

## Combo 1

Proof → Chocolate → Bake

Result:
- Strong sweet pastry
- Better baked result

---

## Combo 2

Bake → Sugar Glaze (while warm)

Result:
- Avoid sticky
- Gain premium tags

---

## Combo 3

Fold + Butter

Result:
- Flaky synergy

---
