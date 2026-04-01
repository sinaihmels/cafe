class_name DemoEncounterState
extends Resource

@export var active_customer: DemoCustomerInstance
@export var turn_number: int = 1
@export var turn_phase: int = DemoEnums.TurnPhase.IDLE
@export var pending_penalties: int = 0
@export var serve_history: Array[Dictionary] = []
@export var completed: bool = false
@export var success: bool = false
@export var last_result: Dictionary = {}
@export var status_message: String = ""
@export var food_state: DemoFoodState = DemoFoodState.new()
