class_name UiTextureLibrary
extends RefCounted

# Content resources own the editor-visible textures; these helpers only provide null-safe fallbacks.
const CARD_PLACEHOLDER: Texture2D = preload("res://assets/demo/cards/base_card.png")
const CUSTOMER_PLACEHOLDER: Texture2D = preload("res://assets/demo/customers/customer_placeholder.png")
const DOUGH_PLACEHOLDER: Texture2D = preload("res://assets/demo/doughs/dough_placeholder.png")
const DISH_PLACEHOLDER: Texture2D = preload("res://assets/demo/dish/dish_placeholder.png")
const PREP_AREA_BASE: Texture2D = preload("res://assets/demo/dish/dough_area_base.png")
const PREP_AREA_EMPTY: Texture2D = preload("res://assets/demo/dish/dough_area_empty.png")
const PREP_AREA_OVERLAY: Texture2D = preload("res://assets/demo/dish/dough_with_items_overlay.png")
const FINISHED_PASTRY_STAGE: Texture2D = preload("res://assets/demo/dish/baked_pastry.png")
const FINISHED_PASTRY_STAGE_OVERLAY: Texture2D = preload("res://assets/demo/dish/formed_pastry_overlay.png")
const OVEN_PLACEHOLDER: Texture2D = preload("res://assets/demo/oven/oven_placeholder.png")
const OVEN_STAGE_EMPTY: Texture2D = preload("res://assets/demo/oven/oven_empty.png")
const OVEN_STAGE_LOADED: Texture2D = preload("res://assets/demo/oven/oven_loaded.png")
const OVEN_STAGE_READY: Texture2D = preload("res://assets/demo/oven/oven_ready.png")
const OVEN_STAGE_NEEDS_BAKE: Texture2D = preload("res://assets/demo/oven/oven_needs_bake.png")
const OVEN_STAGE_PASTRY_OVERLAY: Texture2D = preload("res://assets/demo/oven/pastry_on_oven_rack_overlay.png")
const OVEN_STAGE_BAKED_OVERLAY: Texture2D = preload("res://assets/demo/oven/baked_pastry_on_oven_rack_overlay.png")
const UI_BACKGROUND: Texture2D = preload("res://assets/demo/ui/demo_background.png")

static func background_texture() -> Texture2D:
	return UI_BACKGROUND

static func card_texture(card_def: CardDef) -> Texture2D:
	if card_def != null and card_def.art != null:
		return card_def.art
	return CARD_PLACEHOLDER

static func customer_texture(customer_def: CustomerDef) -> Texture2D:
	if customer_def != null and customer_def.portrait != null:
		return customer_def.portrait
	return CUSTOMER_PLACEHOLDER

static func dough_texture(dough_def: DoughDef) -> Texture2D:
	if dough_def != null and dough_def.art != null:
		return dough_def.art
	return DOUGH_PLACEHOLDER

static func pastry_texture(pastry: PastryInstance) -> Texture2D:
	if pastry != null and pastry.art != null:
		return pastry.art
	return DOUGH_PLACEHOLDER

static func item_texture(item_def: ItemDef) -> Texture2D:
	if item_def != null and item_def.art != null:
		return item_def.art
	return DISH_PLACEHOLDER

static func prep_area_texture(cafe_state: CafeState = null) -> Texture2D:
	if cafe_state == null or cafe_state.active_pastry == null:
		return PREP_AREA_EMPTY
	return PREP_AREA_BASE

static func prep_area_overlay_texture(cafe_state: CafeState = null) -> Texture2D:
	if cafe_state == null or cafe_state.active_pastry == null:
		return null
	return PREP_AREA_OVERLAY

static func equipment_texture(equipment_def: EquipmentDef) -> Texture2D:
	if equipment_def != null and equipment_def.icon != null:
		return equipment_def.icon
	return CARD_PLACEHOLDER

static func decoration_texture(decoration_def: DecorationDef) -> Texture2D:
	if decoration_def != null and decoration_def.icon != null:
		return decoration_def.icon
	return CARD_PLACEHOLDER

static func shop_upgrade_texture(upgrade_def: ShopUpgradeDef) -> Texture2D:
	if upgrade_def != null and upgrade_def.icon != null:
		return upgrade_def.icon
	return CARD_PLACEHOLDER

static func reward_texture(content_library: ContentLibrary, reward_def: RewardDef) -> Texture2D:
	if reward_def != null and reward_def.icon != null:
		return reward_def.icon
	if reward_def != null and reward_def.reward_type == GameEnums.RewardType.ADD_CARD_TO_RUN_DECK:
		return card_texture(content_library.get_card(reward_def.payload_id))
	return CARD_PLACEHOLDER

static func oven_stage_texture(cafe_state: CafeState = null) -> Texture2D:
	if cafe_state == null or cafe_state.oven_pastry == null:
		if cafe_state != null and cafe_state.active_pastry != null and cafe_state.oven_mode == &"":
			return OVEN_STAGE_NEEDS_BAKE
		return OVEN_STAGE_EMPTY
	match cafe_state.oven_mode:
		&"ready":
			return OVEN_STAGE_READY
		&"proofing", &"baking":
			return OVEN_STAGE_LOADED
		_:
			if cafe_state.oven_pastry.has_pastry_state(&"proofed"):
				return OVEN_STAGE_NEEDS_BAKE
			return OVEN_STAGE_LOADED

static func oven_stage_overlay_texture(cafe_state: CafeState = null) -> Texture2D:
	if cafe_state == null or cafe_state.oven_pastry == null:
		return null
	if cafe_state.oven_mode == &"ready":
		return OVEN_STAGE_BAKED_OVERLAY
	return OVEN_STAGE_PASTRY_OVERLAY

static func finished_pastry_texture(cafe_state: CafeState = null) -> Texture2D:
	if cafe_state == null or cafe_state.plated_pastries.is_empty():
		return null
	return FINISHED_PASTRY_STAGE

static func finished_pastry_overlay_texture(cafe_state: CafeState = null) -> Texture2D:
	if cafe_state == null or cafe_state.plated_pastries.is_empty():
		return null
	return FINISHED_PASTRY_STAGE_OVERLAY

static func offer_texture(content_library: ContentLibrary, offer_def: CardOfferDef) -> Texture2D:
	if offer_def != null and offer_def.icon != null:
		return offer_def.icon
	if offer_def != null and offer_def.offer_type == GameEnums.OfferType.RUN_CARD:
		return card_texture(content_library.get_card(offer_def.payload_id))
	return CARD_PLACEHOLDER
