class_name PlayerState
extends Resource

@export var energy: int = 3
@export var max_energy: int = 3
@export var reputation: int = 10
@export var max_reputation: int = 10
@export var chaos: int = 0

func reset_turn_energy() -> void:
	energy = max_energy
