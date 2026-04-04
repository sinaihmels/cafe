class_name ContentLibrary
extends RefCounted

const DOUGH_PATHS: Array[String] = [
	"res://data/doughs/sweet_dough.tres",
	"res://data/doughs/savory_dough.tres",
	"res://data/doughs/laminated_dough.tres",
	"res://data/doughs/sourdough.tres",
]

const CARD_PATHS: Array[String] = [
	"res://data/cards/starter_bake.tres",
	"res://data/cards/starter_serve.tres",
	"res://data/cards/starter_decorate.tres",
	"res://data/cards/starter_focus.tres",
	"res://data/cards/starter_second_wind.tres",
	"res://data/cards/starter_cheese.tres",
	"res://data/cards/starter_herbs.tres",
	"res://data/cards/starter_fold.tres",
	"res://data/cards/starter_culture.tres",
	"res://data/cards/starter_proof.tres",
	"res://data/cards/reward_chocolate.tres",
	"res://data/cards/reward_cinnamon.tres",
	"res://data/cards/reward_flash_bake.tres",
]

const CUSTOMER_PATHS: Array[String] = [
	"res://data/customers/starter_regular.tres",
	"res://data/customers/sweet_tooth_customer.tres",
	"res://data/customers/fast_customer.tres",
	"res://data/customers/quality_customer.tres",
	"res://data/customers/critic_boss.tres",
]

const ITEM_PATHS: Array[String] = [
	"res://data/ingredients/flour.tres",
	"res://data/ingredients/butter.tres",
	"res://data/ingredients/sugar.tres",
	"res://data/ingredients/chocolate.tres",
	"res://data/ingredients/cinnamon.tres",
	"res://data/ingredients/cream.tres",
	"res://data/ingredients/dough.tres",
	"res://data/ingredients/sweet_dough.tres",
	"res://data/ingredients/savory_dough.tres",
	"res://data/ingredients/laminated_dough.tres",
	"res://data/ingredients/sourdough.tres",
	"res://data/ingredients/chocolate_dough.tres",
	"res://data/ingredients/pastry.tres",
	"res://data/ingredients/sweet_pastry.tres",
	"res://data/ingredients/savory_pastry.tres",
	"res://data/ingredients/laminated_pastry.tres",
	"res://data/ingredients/sourdough_loaf.tres",
	"res://data/ingredients/chocolate_pastry.tres",
	"res://data/ingredients/decorated_pastry.tres",
	"res://data/ingredients/perfect_sweet_pastry.tres",
	"res://data/ingredients/burned.tres",
]

const RECIPE_PATHS: Array[String] = [
	"res://data/recipes/flour_butter_to_dough.tres",
	"res://data/recipes/dough_sugar_to_sweet_dough.tres",
	"res://data/recipes/dough_chocolate_to_chocolate_dough.tres",
	"res://data/recipes/bake_dough_to_pastry.tres",
	"res://data/recipes/bake_sweet_dough_to_sweet_pastry.tres",
	"res://data/recipes/bake_savory_dough_to_savory_pastry.tres",
	"res://data/recipes/bake_laminated_dough_to_laminated_pastry.tres",
	"res://data/recipes/bake_sourdough_to_sourdough_loaf.tres",
	"res://data/recipes/bake_chocolate_dough_to_chocolate_pastry.tres",
	"res://data/recipes/decorate_pastry_to_decorated_pastry.tres",
	"res://data/recipes/decorate_sweet_pastry_to_perfect_sweet_pastry.tres",
	"res://data/recipes/decorate_savory_pastry.tres",
	"res://data/recipes/decorate_laminated_pastry.tres",
	"res://data/recipes/decorate_sourdough_loaf.tres",
]

const EQUIPMENT_PATHS: Array[String] = [
	"res://data/equipment/coffee_machine.tres",
	"res://data/equipment/display_case.tres",
]

const DECORATION_PATHS: Array[String] = [
	"res://data/decorations/chalkboard_menu.tres",
	"res://data/decorations/counter_flowers.tres",
	"res://data/decorations/checker_floor.tres",
	"res://data/decorations/pastry_shelf.tres",
	"res://data/decorations/awning_sign.tres",
]

const SHOP_UPGRADE_PATHS: Array[String] = [
	"res://data/shop_upgrades/oven_slot_upgrade.tres",
	"res://data/shop_upgrades/prep_counter_upgrade.tres",
	"res://data/shop_upgrades/tip_jar_upgrade.tres",
]

const BUFF_PATHS: Array[String] = [
	"res://data/buffs/second_wind_buff.tres",
	"res://data/buffs/focused_service_buff.tres",
	"res://data/buffs/display_case_buff.tres",
	"res://data/buffs/tip_jar_buff.tres",
	"res://data/buffs/oven_mastery_buff.tres",
	"res://data/buffs/prep_station_buff.tres",
	"res://data/buffs/barista_rhythm_buff.tres",
]

const STATUS_PATHS: Array[String] = [
	"res://data/statuses/impatient_status.tres",
	"res://data/statuses/critic_status.tres",
	"res://data/statuses/warm_status.tres",
]

const REWARD_PATHS: Array[String] = [
	"res://data/rewards/reward_add_chocolate.tres",
	"res://data/rewards/reward_flash_bake.tres",
	"res://data/rewards/reward_focus_buff.tres",
	"res://data/rewards/reward_meta_tokens.tres",
]

const OFFER_PATHS: Array[String] = [
	"res://data/offers/offer_chocolate.tres",
	"res://data/offers/offer_cinnamon.tres",
	"res://data/offers/offer_second_wind_buff.tres",
]

var doughs: Dictionary[StringName, DoughDef] = {}
var cards: Dictionary[StringName, CardDef] = {}
var customers: Dictionary[StringName, CustomerDef] = {}
var items: Dictionary[StringName, ItemDef] = {}
var recipes: Dictionary[StringName, RecipeDef] = {}
var equipment: Dictionary[StringName, EquipmentDef] = {}
var decorations: Dictionary[StringName, DecorationDef] = {}
var shop_upgrades: Dictionary[StringName, ShopUpgradeDef] = {}
var buffs: Dictionary[StringName, BuffDef] = {}
var statuses: Dictionary[StringName, StatusDef] = {}
var rewards: Dictionary[StringName, RewardDef] = {}
var offers: Dictionary[StringName, CardOfferDef] = {}

func load_all() -> void:
	_populate_index(doughs, DOUGH_PATHS, &"dough_id")
	_populate_index(cards, CARD_PATHS, &"card_id")
	_populate_index(customers, CUSTOMER_PATHS, &"customer_id")
	_populate_index(items, ITEM_PATHS, &"item_id")
	_populate_index(recipes, RECIPE_PATHS, &"recipe_id")
	_populate_index(equipment, EQUIPMENT_PATHS, &"equipment_id")
	_populate_index(decorations, DECORATION_PATHS, &"decoration_id")
	_populate_index(shop_upgrades, SHOP_UPGRADE_PATHS, &"upgrade_id")
	_populate_index(buffs, BUFF_PATHS, &"modifier_id")
	_populate_index(statuses, STATUS_PATHS, &"modifier_id")
	_populate_index(rewards, REWARD_PATHS, &"reward_id")
	_populate_index(offers, OFFER_PATHS, &"offer_id")

func get_dough(dough_id: StringName) -> DoughDef:
	return doughs.get(dough_id) as DoughDef

func get_card(card_id: StringName) -> CardDef:
	return cards.get(card_id) as CardDef

func get_customer(customer_id: StringName) -> CustomerDef:
	return customers.get(customer_id) as CustomerDef

func get_item(item_id: StringName) -> ItemDef:
	return items.get(item_id) as ItemDef

func get_recipe(recipe_id: StringName) -> RecipeDef:
	return recipes.get(recipe_id) as RecipeDef

func get_equipment(equipment_id: StringName) -> EquipmentDef:
	return equipment.get(equipment_id) as EquipmentDef

func get_decoration(decoration_id: StringName) -> DecorationDef:
	return decorations.get(decoration_id) as DecorationDef

func get_shop_upgrade(upgrade_id: StringName) -> ShopUpgradeDef:
	return shop_upgrades.get(upgrade_id) as ShopUpgradeDef

func get_buff(buff_id: StringName) -> BuffDef:
	return buffs.get(buff_id) as BuffDef

func get_status(status_id: StringName) -> StatusDef:
	return statuses.get(status_id) as StatusDef

func get_reward(reward_id: StringName) -> RewardDef:
	return rewards.get(reward_id) as RewardDef

func get_offer(offer_id: StringName) -> CardOfferDef:
	return offers.get(offer_id) as CardOfferDef

func get_modifier(modifier_id: StringName) -> ModifierDef:
	if buffs.has(modifier_id):
		return buffs.get(modifier_id) as ModifierDef
	if statuses.has(modifier_id):
		return statuses.get(modifier_id) as ModifierDef
	return null

func build_card_instance(card_id: StringName) -> CardInstance:
	var card_def: CardDef = get_card(card_id)
	if card_def == null:
		return null
	var instance: CardInstance = CardInstance.new()
	instance.card_def = card_def
	return instance

func _populate_index(target: Dictionary, paths: Array[String], property_name: StringName) -> void:
	target.clear()
	for path in paths:
		var resource: Resource = load(path) as Resource
		if resource == null:
			continue
		var resource_id: Variant = resource.get(property_name)
		if resource_id == null:
			continue
		target[StringName(resource_id)] = resource
