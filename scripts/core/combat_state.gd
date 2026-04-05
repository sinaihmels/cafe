class_name CombatState
extends Resource

@export var turn_number: int = 1
@export var turn_state: int = GameEnums.TurnState.IDLE
@export var active_customers: Array[CustomerInstance] = []
@export var focused_customer_index: int = 0
@export var next_plated_pastry_duplications: int = 0
@export var skip_next_customer_patience_loss: bool = false
@export var next_warm_serve_bonus: bool = false
