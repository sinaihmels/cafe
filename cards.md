# Cards Overview

This document tracks the currently implemented `CardDef` resources in `data/cards`.
It reflects the live game data, not the older concept draft.

## Card Type Labels

- `0 = Ingredient`
- `1 = Process`
- `2 = Technique`
- `3 = Interaction`

Player-facing note:
- The old `utility` bucket has been folded into the visible card families.
- `Serve` is now classified as `Process`.
- `Focus` and `Second Wind` are now classified as `Technique`.

## Summary

- Total implemented cards: `24`
- Ingredient cards: `10`
- Process cards: `8`
- Technique cards: `4`
- Interaction cards: `2`

## Current Availability Snapshot

- Sweet Dough starter deck: `reward_chocolate` x2, `reward_cinnamon`, `starter_vanilla`, `starter_bake` x2, `starter_serve` x2, `starter_sugar_glaze`, `starter_mini_cookies`
- Savory Dough starter deck: `starter_cheese` x2, `starter_tomato_sauce`, `starter_herbs`, `starter_bake` x2, `starter_serve` x2, `starter_egg_wash`, `starter_small_talk`
- Laminated Dough starter deck: `starter_fold` x2, `starter_butter`, `starter_proof` x2, `starter_bake` x2, `starter_serve`, `starter_double_batch`, `starter_perfect_timing`
- Sourdough starter deck: `starter_culture` x2, `starter_lemon`, `starter_proof` x2, `starter_bake` x2, `starter_serve` x2, `starter_decorate`
- Reward cards currently wired into progression: `reward_chocolate`, `reward_flash_bake`
- Shop cards currently wired into progression: `reward_chocolate`, `reward_cinnamon`
- Implemented but not currently surfaced by a starter deck or registered reward/shop source: `starter_focus`, `starter_second_wind`, `starter_strawberry`
- `offer_focus.tres` exists on disk, but it is not currently registered in `ContentLibrary.OFFER_PATHS`, so `starter_focus` is not currently offered in-game

## Ingredient Cards

### Chocolate (`reward_chocolate`)
- Type: `Ingredient`
- Cost: `2`
- Targeting rule: `none`
- Preview: `Add chocolate to the active pastry.`
- Effects: Add pastry tags `sweet`, `chocolaty`, `luxurious`, `pretty`
- Current source: Sweet Dough starter x2, reward `reward_add_chocolate`, shop `offer_chocolate`

### Cinnamon Sugar (`reward_cinnamon`)
- Type: `Ingredient`
- Cost: `1`
- Targeting rule: `none`
- Preview: `Add cinnamon sugar to the active pastry.`
- Effects: Add pastry tags `sweet`, `pretty`, `sticky`
- Current source: Sweet Dough starter x1, shop `offer_cinnamon`

### Butter (`starter_butter`)
- Type: `Ingredient`
- Cost: `1`
- Targeting rule: `none`
- Preview: `Add butter to the active pastry.`
- Effects: Add pastry tag `luxurious`; set pastry flag `butter_applied = true`
- Current source: Laminated Dough starter x1

### Cheese (`starter_cheese`)
- Type: `Ingredient`
- Cost: `1`
- Targeting rule: `none`
- Preview: `Add cheese to the active pastry.`
- Effects: Add pastry tags `savory`, `salty`
- Current source: Savory Dough starter x2

### Feed Starter (`starter_culture`)
- Type: `Ingredient`
- Cost: `1`
- Targeting rule: `none`
- Preview: `Feed the starter to deepen tangy flavor and improve quality.`
- Effects: Add pastry tag `tangy`; increase pastry quality by `1`
- Current source: Sourdough starter x2

### Herbs (`starter_herbs`)
- Type: `Ingredient`
- Cost: `1`
- Targeting rule: `none`
- Preview: `Season the active pastry with herbs.`
- Effects: Add pastry tags `savory`, `pretty`
- Current source: Savory Dough starter x1

### Lemon (`starter_lemon`)
- Type: `Ingredient`
- Cost: `1`
- Targeting rule: `none`
- Preview: `Add lemon to the active pastry.`
- Effects: Add pastry tags `tangy`, `fruity`
- Current source: Sourdough starter x1

### Strawberry (`starter_strawberry`)
- Type: `Ingredient`
- Cost: `2`
- Targeting rule: `none`
- Preview: `Add strawberries to the active pastry.`
- Effects: Add pastry tags `sweet`, `fruity`, `pretty`
- Current source: Implemented only; no active starter, reward, or registered shop source

### Tomato Sauce (`starter_tomato_sauce`)
- Type: `Ingredient`
- Cost: `1`
- Targeting rule: `none`
- Preview: `Add tomato sauce to the active pastry.`
- Effects: Add pastry tags `savory`, `tangy`
- Current source: Savory Dough starter x1

### Vanilla (`starter_vanilla`)
- Type: `Ingredient`
- Cost: `1`
- Targeting rule: `none`
- Preview: `Add vanilla to the active pastry.`
- Effects: Add pastry tag `sweet`
- Current source: Sweet Dough starter x1

## Process Cards

### Flash Bake (`reward_flash_bake`)
- Type: `Process`
- Cost: `0`
- Targeting rule: `none`
- Preview: `50% chance to bake the pastry instantly. 50% chance to burn it.`
- Effects: Instantly resolves a pastry with `50%` burn chance; on success it becomes `baked` and is plated, on failure it becomes `burned` and is plated
- Current source: Reward `reward_flash_bake`

### Bake (`starter_bake`)
- Type: `Process`
- Cost: `1`
- Targeting rule: `none`
- Preview: `Send the active pastry to the oven, or finish baking a proofed pastry already inside.`
- Effects: Sends the active pastry into the oven to bake, or starts baking an already proofed oven pastry
- Current source: All dough starter decks

### Decorate (`starter_decorate`)
- Type: `Process`
- Cost: `2`
- Targeting rule: `select_one_plated_pastry`
- Preview: `Decorate a plated pastry and give it +1 quality.`
- Effects: Add pastry state `decorated`; increase pastry quality by `1`
- Current source: Sourdough starter x1

### Egg Wash (`starter_egg_wash`)
- Type: `Process`
- Cost: `1`
- Targeting rule: `select_one_plated_pastry`
- Preview: `Brush your pastry for a glossy finish.`
- Effects: Add pastry tag `shiny`; if the pastry is `warm`, also add pastry tag `pretty`
- Current source: Savory Dough starter x1

### Fold (`starter_fold`)
- Type: `Process`
- Cost: `2`
- Targeting rule: `none`
- Preview: `Fold the active pastry. Laminated doughs and buttered pastries become flaky.`
- Effects: Add pastry tag `flaky`
- Current source: Laminated Dough starter x2

### Proof (`starter_proof`)
- Type: `Process`
- Cost: `1`
- Targeting rule: `none`
- Preview: `Move the active pastry into the oven to proof for 1 turn.`
- Effects: Sends the active pastry to the oven in proofing mode; after resolution the pastry gains state `proofed` and tag `airy`
- Current source: Laminated Dough starter x2, Sourdough starter x2

### Serve (`starter_serve`)
- Type: `Process`
- Cost: `0`
- Targeting rule: `select_one_customer_and_one_plated_pastry`
- Preview: `Serve 1 plated pastry to 1 customer.`
- Effects: Serve a plated pastry to a selected customer; scoring checks baked state, tags, quality, and customer preferences
- Current source: All dough starter decks

### Sugar Glaze (`starter_sugar_glaze`)
- Type: `Process`
- Cost: `3`
- Targeting rule: `select_one_plated_pastry`
- Preview: `Glaze your pastry. Warm pastries become beautiful; cold pastries become sticky.`
- Effects: Add pastry tags `sweet`, `luxurious`, `shiny`, `pretty`; if the pastry is not `warm`, also add pastry tag `sticky`
- Current source: Sweet Dough starter x1

## Technique Cards

### Double Batch (`starter_double_batch`)
- Type: `Technique`
- Cost: `3`
- Targeting rule: `none`
- Preview: `Create 2x more pastries this round.`
- Effects: Set encounter flag `next_plated_pastry_duplications += 1`
- Current source: Laminated Dough starter x1

### Focus (`starter_focus`)
- Type: `Technique`
- Cost: `1`
- Targeting rule: `none`
- Preview: `Draw 1 card.`
- Effects: Draw `1` card
- Current source: Implemented only; `offer_focus.tres` exists on disk but is not currently registered in `ContentLibrary.OFFER_PATHS`

### Perfect Timing (`starter_perfect_timing`)
- Type: `Technique`
- Cost: `1`
- Targeting rule: `none`
- Preview: `Your next warm pastry gets bonus appeal.`
- Effects: Set encounter flag `next_warm_serve_bonus = true`
- Current source: Laminated Dough starter x1

### Second Wind (`starter_second_wind`)
- Type: `Technique`
- Cost: `0`
- Targeting rule: `none`
- Preview: `Gain 1 energy.`
- Effects: Gain `1` energy
- Current source: Implemented only; no active starter, reward, or registered shop source

## Interaction Cards

### Mini Cookies (`starter_mini_cookies`)
- Type: `Interaction`
- Cost: `0`
- Targeting rule: `none`
- Preview: `Give out mini cookies. Increase all customer patience by 1.`
- Effects: Increase all customer patience by `1`
- Current source: Sweet Dough starter x1

### Small Talk (`starter_small_talk`)
- Type: `Interaction`
- Cost: `2`
- Targeting rule: `none`
- Preview: `Buy a little more time and prevent patience loss this turn.`
- Effects: Set encounter flag `skip_next_customer_patience_loss = true`
- Interaction traits: `talk`
- Current source: Savory Dough starter x1

## Notes

- A targeting rule of `none` means the card has no explicit UI target selection. In practice, these cards usually resolve against the current active pastry or the current encounter state.
- The pastry-building cards use effects and context checks, so some cards have extra gameplay requirements beyond what is written in `targeting_rules`.
- Example: `starter_fold` uses `targeting_rules = none`, but it is only playable when the active pastry is laminated or has the `butter_applied` flag.
