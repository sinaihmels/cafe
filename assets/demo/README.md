# Demo Art Drop Folder

Place your PNG files inside these folders. The demo UI auto-loads by filename:

- `cards/<card_id>.png` (example: `cards/card_chocolate.png`)
- `customers/<customer_id>.png` (example: `customers/customer_critic_guest.png`)
- `doughs/<dough_id>.png` (example: `doughs/sweet_dough.png`)
- `dish/<stage_key>.png` (example: `dish/dough_with_items.png`)
- `oven/<stage_key>.png` (example: `oven/oven_ready.png`)

Fallback files (used when a specific image is missing):

- `cards/base_card.png`
- `customers/customer_placeholder.png`
- `doughs/dough_placeholder.png`
- `dish/dish_placeholder.png`
- `oven/oven_placeholder.png`

Optional global UI background (auto-applied to the demo view):

- `ui/demo_background.png`
