class_name RewardDef
extends Resource

@export var reward_id: StringName = &""
@export var display_name: String = ""
@export var icon: Texture2D
@export_multiline var description: String = ""
@export var reward_type: int = GameEnums.RewardType.ADD_CARD_TO_RUN_DECK
@export var payload_id: StringName = &""
@export var amount: int = 0
