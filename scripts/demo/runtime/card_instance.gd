class_name DemoCardInstance
extends Resource

@export var card_def: DemoCardDef
@export var cost_modifier: int = 0
@export var upgrades: int = 0

func get_cost() -> int:
	if card_def == null:
		return 0
	return maxi(0, card_def.mana_cost + cost_modifier)

func get_card_name() -> String:
	if card_def == null:
		return "Unknown Card"
	return card_def.name

func get_description() -> String:
	if card_def == null:
		return ""
	return card_def.description
