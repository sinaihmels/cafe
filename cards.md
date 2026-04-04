# Cards

# Tag Cards
- Chocolate
    {
        display_name: Chocolate
        energy_cost: 2
        tags: [sweet, chocolaty, luxurious, pretty]
        preview_text: Add Chocolate
    }
- Cinnamon Sugar
    {
        display_name: Cinnamon Sugar
        energy_cost: 1
        tags: [sweet, pretty, sticky]
        preview_text: Add Cinnamon sugar
    }
- Cheese
    {
        display_name: Cheese
        energy_cost: 1
        tags: [savory, salty]
        preview_text: Add Cheese
    }
- Tomato Sauce
    {
        display_name: Tomato Sauce
        energy_cost: 1
        tags: [savory, tangy]
        preview_text: Add Tomato Sauce
    }
- Vanilla
    {
        display_name: Vanilla
        energy_cost: 1
        tags: [sweet]
        preview_text: Add Vanilla
    }
- Strawberry
    {
        display_name: Strawberry
        energy_cost: 2
        tags: [sweet, fruity, pretty]
        preview_text: Add Strawberry
    }
-  Lemon
    {
        display_name: Lemon
        energy_cost: 1
        tags: [tangy, fruity]
    }
- Butter
    {
        display_name: Butter
        energy_cost: 1
        tags: [luxurious]
        preview_text: Add Butter
    } 
# Process Cards
- Fold
    {
        display_name: Fold
        energy_cost: 2
        tags: [flaky (only if laminated dough or if there is butter in the pastry)]
    }
- Proof
    {
        display_name: Proof
        energy_cost: 1
        tags: [airy]
        status: [proofed]
    }
- Bake
    {
        display_name: Bake
        energy_cost: 1
        status: [baked (after 1 turn), burned (if left in the oven for more than 1 turn), warm (for the turn after the pastry was taken out of the oven)]
        preview_text: Bake!
    }
- Flash Bake
    {
        display_name: Flash Bake
        energy_cost: 0
        status: [baked(50% chance it is baked), burnt(50% chance it is burned)]
        preview_text: 50% chance for baked, 50% chance for burned
    }
- Sugar Glaze
    {
        display_name: Sugar Glaze
        energy_cost: 3
        tags: [sweet, luxurious, shiny, pretty, (if the pastry is not warm add tag "sticky")]
        preview_text: Glaze your pastry. Warm pastries become beautiful; cold pastries become sticky.
    }
- Decorate
    {
        display_name: Decorate
        energy_cost: 2
        status: [decorated]
        preview_text: Decorate
    }
- Egg Wash 
    {
        display_name: "Egg Wash",
        energy_cost: 1,
        tags: [shiny, if combined with baked in this turn add pretty]
        preview_text: "Brush your pastry for a glossy finish."
    }
- Serve 
    {
        display_name: Serve,
        energy_cost: 0,
        preview_text: Serve the pastry to a customer. 
    }

# Buff cards (Buffs the current turn)
- Double Batch
    {
        display_name: Double Batch
        energy_cost: 3
        preview_text: Create 2x more pastries this round
    }
- Mini Cookies
    {
        display_name: Mini Cookies
        energy_cost: 0
        preview_text: Give out Mini Cookies. Increase patience by 1
    }
- Small Talk
    {
        display_name: Small Talk
        energy_cost: 2
        preview_text: Buy a little more time and prevent patience loss this turn
    }
- Perfect Timing
    {
        display_name: Perfect Timing
        energy_cost: 1
        preview_text: "Your next warm pastry gets bonus appeal"
    }