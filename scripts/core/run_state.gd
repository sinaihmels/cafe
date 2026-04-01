class_name RunState
extends Resource

@export var day_number: int = 1
@export var run_phase: int = GameEnums.RunPhase.PREP_PHASE
@export var seed: int = 0
@export var pending_reward_ids: PackedStringArray = []
@export var pending_event_id: StringName = &""
@export var pending_event_description: String = ""
@export var pending_event_option_ids: PackedStringArray = []
@export var unlocked_ids: PackedStringArray = []
@export var summary_message: String = ""
