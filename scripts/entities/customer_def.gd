class_name CustomerDef
extends Resource

@export var customer_id: StringName
@export var display_name: String = ""
@export var portrait: Texture2D
@export var order_id: StringName
@export var preferences: PackedStringArray = []
@export var required_tags: PackedStringArray = []
@export var bonus_tags: PackedStringArray = []
@export var forbidden_tags: PackedStringArray = []
@export var minimum_quality: int = 0
@export var base_reputation: int = 1
@export var bonus_reputation_per_match: int = 1
@export var bonus_tips_per_match: int = 1
@export var patience: int = 3
@export var hunger: int = 1
@export var reward: int = 2
@export var stress_damage: int = 2
@export var customer_type: int = GameEnums.CustomerType.REGULAR
@export var personality_modifiers: Dictionary = {}
@export var talent_ids: PackedStringArray = []
@export var starting_status_ids: PackedStringArray = []
