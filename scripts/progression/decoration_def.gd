class_name DecorationDef
extends Resource

@export var decoration_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var slot: int = GameEnums.DecorationSlot.WALL
@export var cost: int = 0
@export var unlocked_by_default: bool = false
