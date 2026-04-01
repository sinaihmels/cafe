class_name CombatState
extends Resource

@export var turn_number: int = 1
@export var turn_state: int = GameEnums.TurnState.IDLE
@export var active_customers: Array[CustomerInstance] = []
