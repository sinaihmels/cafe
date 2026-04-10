# Art Production Todo List

This checklist is for drawing the game's art from zero.

Current assumptions:

- No cafe nook for now.
- No seated customer sprites.
- No walking customer sprites.
- One cozy bakery storefront background that can scale to different screen sizes.
- Keep layered source files, then export PNGs for the game.

## 1) Art Pipeline Setup

- [ ] Create layered source files for background, cards, portraits, icons, prep area, and oven.
- [ ] Draw background masters at `3840 x 2160` minimum. `5120 x 2880` is even safer.
- [ ] Draw kitchen stage assets at `1024 x 1024` minimum. `2048 x 2048` is safer if you want zoom room.
- [ ] Draw card frames at `1024 x 1434`. If you prefer, paint card source art at `2048 x 2868` and export down.
- [ ] Draw portraits and icons at `1024 x 1024`, then export smaller versions as needed.
- [ ] Keep every prop on separate transparent layers so you can move or resize it later.
- [ ] Keep the center of the customer lane visually lighter so request bubbles stay readable.
- [ ] Do not bake gameplay text into art, except small decorative signs like `OPEN`.
- [ ] Test exported assets at `1280 x 720`, `1920 x 1080`, and `2560 x 1440`.
- [ ] Save final runtime exports as PNG.

## 2) Phase 1: Playably Complete Art

This is the smallest set that makes the current build feel fully illustrated.

### A. Main Environment Background

Current runtime export:

- [ ] `assets/demo/ui/demo_background.png`

Recommended source layers for that background:

- [ ] Back wall base colors and wall trim
- [ ] Storefront window band behind the customer queue
- [ ] Front door
- [ ] Chalkboard menu or pastry poster
- [ ] Three pendant lamps above the customer lane
- [ ] Counter front texture or paneling
- [ ] Counter prop cluster: pastry dome, napkins, tip jar
- [ ] Prep shelf cluster: bowls, jars, flour bag, utensils
- [ ] Oven hood
- [ ] Oven tile backsplash or warm glow area
- [ ] Right-side finishing prop: plant or coat stand
- [ ] Floor pattern and soft shadow pass
- [ ] Ambient lighting pass to unify the whole scene

Keep out of this version:

- [ ] No cafe nook
- [ ] No extra customer seating area
- [ ] No walking/sitting customer sprite requirements

### B. Prep Area and Finished Pastry Stage

These are the files the current runtime expects:

- [ ] `assets/demo/dish/dough_area_empty.png`
- [ ] `assets/demo/dish/dough_area_base.png`
- [ ] `assets/demo/dish/dough_with_items_overlay.png`
- [ ] `assets/demo/dish/formed_pastry_overlay.png`
- [ ] `assets/demo/dish/baked_pastry.png`
- [ ] `assets/demo/dish/dish_placeholder.png`

Optional helper exports if you want extra source flexibility:

- [ ] `assets/demo/dish/dough_with_items.png`
- [ ] `assets/demo/dish/formed_pastry.png`
- [ ] `assets/demo/dish/pastry.png`

### C. Oven Stage

These are the files the current runtime expects:

- [ ] `assets/demo/oven/oven_empty.png`
- [ ] `assets/demo/oven/oven_loaded.png`
- [ ] `assets/demo/oven/oven_ready.png`
- [ ] `assets/demo/oven/oven_needs_bake.png`
- [ ] `assets/demo/oven/pastry_on_oven_rack_overlay.png`
- [ ] `assets/demo/oven/baked_pastry_on_oven_rack_overlay.png`
- [ ] `assets/demo/oven/oven_placeholder.png`

Optional helper export:

- [ ] `assets/demo/oven/oven_base.png`

### D. Card Frames and Card Art

Card frame exports:

- [ ] `assets/demo/cards/base_card.png`
- [ ] `assets/demo/cards/base_card_process.png`
- [ ] `assets/demo/cards/base_card_technique.png`
- [ ] `assets/demo/cards/base_card_interaction.png`

Shared card art exports currently used by the project:

- [ ] `assets/demo/cards/card_chocolate.png`
- [ ] `assets/demo/cards/card_cinnamon_sugar.png`
- [ ] `assets/demo/cards/card_flash_bake.png`
- [ ] `assets/demo/cards/card_bake.png`
- [ ] `assets/demo/cards/card_cream.png`
- [ ] `assets/demo/cards/card_coffee.png`
- [ ] `assets/demo/cards/card_focus.png`
- [ ] `assets/demo/cards/card_mix.png`
- [ ] `assets/demo/cards/card_tell_joke.png`

Cards that still need a real illustration pass because they currently point at placeholder/base art:

- [ ] `starter_decorate`
- [ ] `starter_egg_wash`
- [ ] `starter_serve`
- [ ] `starter_sugar_glaze`

If you later want every card concept to have its own unique illustration, these are the current card ids:

- [ ] `reward_chocolate`
- [ ] `reward_cinnamon`
- [ ] `reward_flash_bake`
- [ ] `starter_bake`
- [ ] `starter_butter`
- [ ] `starter_cheese`
- [ ] `starter_culture`
- [ ] `starter_decorate`
- [ ] `starter_double_batch`
- [ ] `starter_egg_wash`
- [ ] `starter_focus`
- [ ] `starter_fold`
- [ ] `starter_herbs`
- [ ] `starter_lemon`
- [ ] `starter_mini_cookies`
- [ ] `starter_perfect_timing`
- [ ] `starter_proof`
- [ ] `starter_second_wind`
- [ ] `starter_serve`
- [ ] `starter_small_talk`
- [ ] `starter_strawberry`
- [ ] `starter_sugar_glaze`
- [ ] `starter_tomato_sauce`
- [ ] `starter_vanilla`

### E. Customer Portraits

Current must-have portraits:

- [ ] `assets/demo/customers/customer_placeholder.png`
- [ ] `assets/demo/customers/customer_regular_guest.png`
- [ ] `assets/demo/customers/customer_patient_guest.png`
- [ ] `assets/demo/customers/customer_impatient_guest.png`
- [ ] `assets/demo/customers/customer_critic_guest.png`
- [ ] `assets/demo/customers/customer_final_critic.png`

Future-ready portrait if you bring this type back into active content:

- [ ] `assets/demo/customers/customer_chaotic_guest.png`

### F. Dough Art

Current dough exports:

- [ ] `assets/demo/doughs/dough_placeholder.png`
- [ ] `assets/demo/doughs/sweet_dough.png`
- [ ] `assets/demo/doughs/laminated_dough.png`
- [ ] `assets/demo/doughs/savory_dough.png`
- [ ] `assets/demo/doughs/sourdough.png`

### G. Progression and Shop Icons

These do not all need fully separate paintings. Many can be cropped or simplified from larger art.

Decoration icons:

- [ ] `awning_sign`
- [ ] `chalkboard_menu`
- [ ] `checker_floor`
- [ ] `counter_flowers`
- [ ] `pastry_shelf`

Equipment icons:

- [ ] `coffee_machine`
- [ ] `display_case`

Offer icons:

- [ ] `offer_chocolate`
- [ ] `offer_cinnamon`
- [ ] `offer_focus`
- [ ] `offer_second_wind_buff`

Reward icons:

- [ ] `reward_add_chocolate`
- [ ] `reward_flash_bake`
- [ ] `reward_focus_buff`
- [ ] `reward_meta_tokens`

Shop upgrade icons:

- [ ] `oven_slot_upgrade`
- [ ] `prep_counter_upgrade`
- [ ] `tip_jar_upgrade`

## 3) Phase 2: Ingredient and Pastry Icons

These resources already have art fields or will benefit from item art as more UI comes online.
You can often derive these from the larger dough/pastry illustrations instead of painting each one from scratch.

- [ ] `burned`
- [ ] `butter`
- [ ] `chocolate`
- [ ] `chocolate_dough`
- [ ] `chocolate_pastry`
- [ ] `cinnamon`
- [ ] `cream`
- [ ] `decorated_pastry`
- [ ] `dough`
- [ ] `flour`
- [ ] `laminated_dough`
- [ ] `laminated_pastry`
- [ ] `pastry`
- [ ] `perfect_sweet_pastry`
- [ ] `savory_dough`
- [ ] `savory_pastry`
- [ ] `sourdough`
- [ ] `sourdough_loaf`
- [ ] `sugar`
- [ ] `sweet_dough`
- [ ] `sweet_pastry`

## 4) Phase 3: UI Polish Pass

These are not the first files to paint, but they will matter if you want the whole game to feel custom instead of prototype-like.

- [ ] Mana icon or orb
- [ ] Energy bar frame
- [ ] Energy bar fill
- [ ] Request bubble art pass
- [ ] Patience icon
- [ ] Hunger icon
- [ ] Satisfaction icon
- [ ] End turn button skin
- [ ] Choice/reward panel icon frames
- [ ] Card category badge styling
- [ ] Decorative divider lines or panel flourishes

## 5) Recommended Draw Order

Use this order if you want the biggest visual improvement fastest:

1. Draw the full bakery background.
2. Draw the prep area and oven stage assets.
3. Draw the four card frames.
4. Draw the nine shared card illustrations currently used by the project.
5. Draw the six customer portraits.
6. Draw the four dough illustrations plus the dough placeholder.
7. Create progression/shop icons by cropping or simplifying from the larger art.
8. Add ingredient and pastry icons.
9. Finish with UI polish assets.

## 6) Reuse Strategy

To keep the workload manageable:

- [ ] Reuse larger dough paintings to create smaller dough/item icons.
- [ ] Reuse pastry paintings to create reward and offer icons where appropriate.
- [ ] Reuse prop art from the background for decoration icons when the object already exists in the scene.
- [ ] Keep one master card frame, then recolor or ornament it into the four card type variants.
- [ ] Build one consistent lighting pass across the bakery so separate assets feel like they belong together.

## 7) Minimum Export Sizes

Use these as a safe baseline:

- Background: `3840 x 2160`
- Stage assets: `1024 x 1024`
- Cards: `1024 x 1434`
- Portraits: `1024 x 1024`
- Icons: `512 x 512` export from `1024 x 1024` source

If you stay at or above these sizes and keep layered source files, you should be able to support different screen sizes without redrawing everything.
