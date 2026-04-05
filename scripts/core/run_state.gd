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
@export var current_day_satisfaction_score: int = 0
@export var last_completed_day_satisfaction_score: int = 0
@export var run_satisfaction_score: int = 0
@export var day_satisfaction_history: Dictionary = {}
@export var scheduled_return_customer_ids_by_day: Dictionary = {}
@export var scheduled_return_visit_counts_by_customer: Dictionary = {}
@export var customer_ids_already_scheduled_to_return: PackedStringArray = []
@export var customer_ids_who_gifted_decoration_this_run: PackedStringArray = []
@export var day_gifted_decoration_ids: PackedStringArray = []
@export var gifted_decoration_ids_this_run: PackedStringArray = []
