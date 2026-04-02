# Demo Drawing Checklist (Layered Setup)

This checklist matches the current demo renderer exactly.  
All files are PNG.

## 1) Card Layering (Slay the Spire style)

Drop into: `assets/demo/cards/`

- `base_card.png`  
Canvas: `1024 x 1434`  
Use this as the reusable card frame/background. You only draw this once.

- Per-card art files:  
`card_chocolate.png`  
`card_cinnamon_sugar.png`  
`card_cream.png`  
`card_mix.png`  
`card_bake.png`  
`card_tell_joke.png`  
`card_apologize.png`  
`card_coffee.png`  
`card_focus.png`  
Canvas for each: `780 x 545` recommended (or larger in same aspect ratio).

Card render behavior:
- Base card is always drawn.
- Per-card image is layered over the art window.
- Mana, title, status, description are drawn as UI text on top.

Card text/art layout reference (on base card canvas `1024x1434`):
- Art window: `x=122, y=286, w=780, h=545`
- Mana plate: `x=34, y=34, w=168, h=168`
- Title area: `x=132, y=84, w=760, h=132`
- Playable/status area: `x=130, y=830, w=760, h=92`
- Description area: `x=118, y=918, w=788, h=438`

Optional compatibility card:
- `card_flash_bake.png`

## 2) Customer Art

Drop into: `assets/demo/customers/`

- `customer_placeholder.png` (fallback)
- `customer_regular_guest.png`
- `customer_patient_guest.png`
- `customer_impatient_guest.png`
- `customer_critic_guest.png`
- `customer_chaotic_guest.png`
- `customer_final_critic.png`

Recommended canvas:
- `512 x 512`

## 3) Dough Art

Drop into: `assets/demo/doughs/`

- `dough_placeholder.png` (fallback)
- `sweet_dough.png`

Recommended canvas:
- `512 x 512`

## 4) Dish Area Layering (Base + Overlay)

Drop into: `assets/demo/dish/`

Base layer (always visible):
- `dough_area_base.png`
Canvas: `512 x 512` recommended

Overlay layers (draw only changing content):
- `dough_with_items_overlay.png`
- `formed_pastry_overlay.png`

Optional fallback:
- `dish_placeholder.png`

Layering behavior:
- `dough_area_base.png` is always rendered.
- Overlay switches by stage and draws above base.

## 5) Oven Area Layering (Base + Overlay)

Drop into: `assets/demo/oven/`

Base layer (always visible):
- `oven_base.png`
Canvas: `512 x 512` recommended

Overlay layers:
- `pastry_on_oven_rack_overlay.png`
- `baked_pastry_on_oven_rack_overlay.png`

Optional fallback:
- `oven_placeholder.png`

Layering behavior:
- `oven_base.png` is always rendered.
- Overlay draws pastry states above the base.

## 6) Optional UI Background

Drop into: `assets/demo/ui/`

- `demo_background.png`

Recommended canvas:
- `2560 x 1440` (scales cleanly to 1080p)
