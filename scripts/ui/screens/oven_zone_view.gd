class_name OvenZoneView
extends PanelContainer

signal oven_item_requested(slot_index: int)

@export var item_card_scene: PackedScene

@onready var _subtitle: Label = $OvenMargin/OvenBody/OvenSubtitle
@onready var _row: HBoxContainer = $OvenMargin/OvenBody/OvenArea/OvenRow

func render(session_service: SessionService, interaction_state: EncounterInteractionState) -> void:
	UiSceneUtils.clear_children(_row)
	_subtitle.text = "1 oven lane"
	var card: ZoneItemCardView = _instantiate_item_card()
	var pastry: PastryInstance = session_service.cafe_state.oven_pastry
	if pastry == null:
		card.configure(UiTextureLibrary.pastry_texture(null), "Oven", "Empty", false, false, false)
		_row.add_child(card)
		return
	var ready: bool = session_service.cafe_state.oven_mode == &"ready"
	var interactable: bool = interaction_state.is_zone_targetable(&"oven", 0) or ready or interaction_state.is_target_selected(&"oven", 0)
	card.configure(
		UiTextureLibrary.pastry_texture(pastry),
		pastry.get_display_name(),
		_status_text(session_service),
		interactable,
		interaction_state.is_target_selected(&"oven", 0),
		interaction_state.is_zone_targetable(&"oven", 0) or ready
	)
	card.action_requested.connect(func() -> void:
		oven_item_requested.emit(0)
	)
	_row.add_child(card)

func _status_text(session_service: SessionService) -> String:
	if session_service.cafe_state.oven_pastry == null:
		return "Empty"
	match session_service.cafe_state.oven_mode:
		&"proofing":
			return "Proofing (%d turn left)" % max(1, session_service.cafe_state.oven_turns_remaining)
		&"baking":
			return "Baking (%d turn left)" % max(1, session_service.cafe_state.oven_turns_remaining)
		&"ready":
			return "Ready to plate"
		_:
			if session_service.cafe_state.oven_pastry.has_pastry_state(&"proofed"):
				return "Proofed and waiting"
			return UiTextFormatter.describe_pastry(session_service.cafe_state.oven_pastry)

func _instantiate_item_card() -> ZoneItemCardView:
	var node: Node = UiSceneUtils.instantiate_required(item_card_scene, "OvenZoneView.item_card_scene")
	var card: ZoneItemCardView = node as ZoneItemCardView
	assert(card != null, "OvenZoneView.item_card_scene must instantiate ZoneItemCardView.")
	return card

func get_pastry_card_control(item_index: int) -> Control:
	if item_index < 0 or item_index >= _row.get_child_count():
		return null
	return _row.get_child(item_index) as Control
