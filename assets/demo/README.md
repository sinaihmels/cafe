# Demo Art Drop Folder

Place your PNG files inside these folders. The demo UI auto-loads by filename:

- `cards/base_card.png` (always-used card frame)
- `cards/<card_id>.png` (example: `cards/card_chocolate.png`)
- `customers/<customer_id>.png` (example: `customers/customer_critic_guest.png`)
- `doughs/<dough_id>.png` (example: `doughs/sweet_dough.png`)
- `dish/dough_area_base.png` plus `dish/<overlay_key>_overlay.png`
- `oven/oven_base.png` plus `oven/<overlay_key>_overlay.png`

Current overlay keys used by the demo:

- Dish overlays: `dough_with_items`, `formed_pastry`
- Oven overlays: `pastry_on_oven_rack`, `baked_pastry_on_oven_rack`

Fallback files (used when a specific image is missing):

- `customers/customer_placeholder.png`
- `doughs/dough_placeholder.png`
- `dish/dish_placeholder.png`
- `oven/oven_placeholder.png`

Optional global UI background (auto-applied to the demo view):

- `ui/demo_background.png`
