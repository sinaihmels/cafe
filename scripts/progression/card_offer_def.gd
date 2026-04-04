class_name CardOfferDef
extends Resource

@export var offer_id: StringName = &""
@export var display_name: String = ""
@export var icon: Texture2D
@export_multiline var description: String = ""
@export var offer_type: int = GameEnums.OfferType.RUN_CARD
@export var payload_id: StringName = &""
@export var cost: int = 0
