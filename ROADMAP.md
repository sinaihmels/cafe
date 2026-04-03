# Roadmap

## Implemented Foundation

The canonical project now includes:

- one routed runtime
- one app shell
- one persistent meta profile
- one kitchen encounter model with prep, oven, and table zones
- authored dough, equipment, decoration, upgrade, buff, status, reward, and offer data
- a run shop and reward flow
- a cafe hub with permanent upgrades and decoration placement
- generic modifier hooks for scalable future content
- canonical smoke test scripts under `tests/game/`

## Thin Content Areas

These systems exist now but still need broader authored content:

- more dough archetypes
- more cards
- more equipment
- more shop upgrades
- more decoration sets
- more customer types and boss variants
- more targeted modifier interactions
- more recipes and ingredient chains

## Recommended Next Expansion Order

1. Add more authored cards and recipes on top of the current kitchen simulation.
2. Expand customer behaviors and status usage before changing the board model.
3. Add more reward and shop offer pools.
4. Broaden equipment and permanent upgrade choices in the cafe hub.
5. Expand decoration inventory and visual feedback while keeping decorations cosmetic.
6. Add more dough archetypes and unlock gates.
7. Add stronger automated test coverage once headless Godot is available in the environment.

## Deferred Decisions

These are intentionally not part of the current foundation pass:

- mid-run save/resume
- overworld map routing
- fully simulated multi-station cafe management outside the current prep/oven/table model
- replacing placeholder assets with final art
