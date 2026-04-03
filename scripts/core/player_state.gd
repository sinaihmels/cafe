class_name PlayerState
extends Resource

@export var stress: int = 16
@export var max_stress: int = 16
@export var energy: int = 3
@export var max_energy: int = 3
@export var reputation: int = 0
@export var max_reputation: int = 0
@export var tips: int = 0
@export var starting_hand_size: int = 5
@export var deck_state: DeckState = DeckState.new()
@export var master_deck_ids: PackedStringArray = []
@export var equipped_equipment_ids: PackedStringArray = []
@export var active_buffs: Array[ModifierInstance] = []
@export var passive_modifiers: Array[ModifierInstance] = []

func reset_turn_energy(extra_energy: int = 0) -> void:
	energy = maxi(0, max_energy + extra_energy)

func heal_stress(amount: int) -> void:
	stress = mini(max_stress, stress + amount)

func lose_stress(amount: int) -> void:
	stress = maxi(0, stress - amount)

func gain_tips(amount: int) -> void:
	tips = maxi(0, tips + amount)

func spend_tips(amount: int) -> bool:
	if amount > tips:
		return false
	tips -= amount
	return true

func clear_run_modifiers() -> void:
	active_buffs.clear()
	passive_modifiers.clear()
