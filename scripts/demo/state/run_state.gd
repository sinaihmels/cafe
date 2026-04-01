class_name DemoRunState
extends Resource

@export var phase: int = DemoEnums.RunPhase.BOOT
@export var run_seed: int = 0
@export var encounter_index: int = 0
@export var tips: int = 0
@export var won: bool = false
@export var lost: bool = false
@export var selected_dough_id: StringName = &""
@export var summary_message: String = ""
@export var pending_reward_choices: Array[DemoRewardDef] = []
@export var pending_shop_offers: Array[DemoRewardDef] = []
@export var current_encounter: DemoEncounterDef
@export var status_message: String = ""
