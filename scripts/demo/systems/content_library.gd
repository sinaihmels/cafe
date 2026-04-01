class_name DemoContentLibrary
extends RefCounted

const DOUGH_PATHS: Array[String] = [
	"res://data/demo/doughs/sweet_dough.tres",
]

const CARD_PATHS: Array[String] = [
	"res://data/demo/cards/chocolate.tres",
	"res://data/demo/cards/cinnamon_sugar.tres",
	"res://data/demo/cards/cream.tres",
	"res://data/demo/cards/mix.tres",
	"res://data/demo/cards/bake.tres",
	"res://data/demo/cards/tell_joke.tres",
	"res://data/demo/cards/apologize.tres",
	"res://data/demo/cards/coffee.tres",
	"res://data/demo/cards/focus.tres",
]

const CUSTOMER_PATHS: Array[String] = [
	"res://data/demo/customers/regular_guest.tres",
	"res://data/demo/customers/patient_guest.tres",
	"res://data/demo/customers/impatient_guest.tres",
	"res://data/demo/customers/critic_guest.tres",
	"res://data/demo/customers/chaotic_guest.tres",
	"res://data/demo/customers/final_critic.tres",
]

const EQUIPMENT_PATHS: Array[String] = [
	"res://data/demo/equipment/coffee_machine.tres",
	"res://data/demo/equipment/display_case.tres",
]

const ENCOUNTER_PATHS: Array[String] = [
	"res://data/demo/encounters/encounter_1.tres",
	"res://data/demo/encounters/encounter_2.tres",
	"res://data/demo/encounters/encounter_3.tres",
	"res://data/demo/encounters/encounter_4.tres",
	"res://data/demo/encounters/encounter_5.tres",
	"res://data/demo/encounters/encounter_6_boss.tres",
]

const REWARD_TEMPLATE_PATHS: Array[String] = [
	"res://data/demo/rewards/heal_reward.tres",
	"res://data/demo/rewards/upgrade_reward.tres",
	"res://data/demo/rewards/coffee_machine_reward.tres",
]

var doughs: Dictionary[StringName, DemoDoughDef] = {}
var cards: Dictionary[StringName, DemoCardDef] = {}
var customers: Dictionary[StringName, DemoCustomerDef] = {}
var equipment: Dictionary[StringName, DemoEquipmentDef] = {}
var encounters: Dictionary[int, DemoEncounterDef] = {}
var reward_templates: Array[DemoRewardDef] = []

func load_all() -> void:
	doughs.clear()
	cards.clear()
	customers.clear()
	equipment.clear()
	encounters.clear()
	reward_templates.clear()
	for path_value in DOUGH_PATHS:
		var path: String = path_value
		var dough: DemoDoughDef = load(path) as DemoDoughDef
		if dough != null:
			doughs[dough.id] = dough
	for path_value in CARD_PATHS:
		var path: String = path_value
		var card: DemoCardDef = load(path) as DemoCardDef
		if card != null:
			cards[card.id] = card
	for path_value in CUSTOMER_PATHS:
		var path: String = path_value
		var customer: DemoCustomerDef = load(path) as DemoCustomerDef
		if customer != null:
			customers[customer.id] = customer
	for path_value in EQUIPMENT_PATHS:
		var path: String = path_value
		var equipment_def: DemoEquipmentDef = load(path) as DemoEquipmentDef
		if equipment_def != null:
			equipment[equipment_def.id] = equipment_def
	for path_value in ENCOUNTER_PATHS:
		var path: String = path_value
		var encounter: DemoEncounterDef = load(path) as DemoEncounterDef
		if encounter != null:
			encounters[encounter.index] = encounter
	for path_value in REWARD_TEMPLATE_PATHS:
		var path: String = path_value
		var reward: DemoRewardDef = load(path) as DemoRewardDef
		if reward != null:
			reward_templates.append(reward)

func get_dough(dough_id: StringName) -> DemoDoughDef:
	return doughs.get(dough_id) as DemoDoughDef

func get_card(card_id: StringName) -> DemoCardDef:
	return cards.get(card_id) as DemoCardDef

func get_customer(customer_id: StringName) -> DemoCustomerDef:
	return customers.get(customer_id) as DemoCustomerDef

func get_equipment(equipment_id: StringName) -> DemoEquipmentDef:
	return equipment.get(equipment_id) as DemoEquipmentDef

func get_encounter(index: int) -> DemoEncounterDef:
	return encounters.get(index) as DemoEncounterDef

func get_reward_templates() -> Array[DemoRewardDef]:
	var copied: Array[DemoRewardDef] = []
	for reward in reward_templates:
		copied.append(reward.duplicate(true) as DemoRewardDef)
	return copied

func has_equipment(equipment_id: StringName) -> bool:
	return equipment.has(equipment_id)
