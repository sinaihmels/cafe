class_name RunState
extends Resource

@export var screen: int = GameEnums.Screen.TITLE
@export var run_phase: int = GameEnums.RunPhase.IDLE
@export var seed: int = 0
@export var day_number: int = 0
@export var pending_day_number: int = 0
@export var encounter_index: int = 0
@export var selected_dough_id: StringName = &""
@export var pending_reward_ids: PackedStringArray = []
@export var pending_shop_offer_ids: PackedStringArray = []
@export var current_customer_ids: PackedStringArray = []
@export var status_message: String = ""
@export var summary_message: String = ""
@export var won: bool = false
@export var lost: bool = false
@export var meta_currency_earned: int = 0
