class_name DemoPlayerState
extends Resource

@export var stress: int = 14
@export var max_stress: int = 14
@export var mana: int = 3
@export var max_mana: int = 3
@export var deck_state: DemoDeckState = DemoDeckState.new()
@export var equipment_ids: PackedStringArray = []
@export var master_deck_ids: PackedStringArray = []
@export var starting_hand_size: int = 5

func reset_turn_mana() -> void:
	mana = max_mana

func heal_stress(amount: int) -> void:
	stress = mini(max_stress, stress + amount)

func lose_stress(amount: int) -> void:
	stress = maxi(0, stress - amount)
