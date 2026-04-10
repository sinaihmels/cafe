class_name TableZoneView
extends Control

signal table_item_requested(item_index: int)

@export var item_card_scene: PackedScene

@onready var _row: HBoxContainer = $TableRow
@onready var _empty_label: Label = $TableEmptyLabel

func render(session_service: SessionService, interaction_state: EncounterInteractionState) -> void:
	UiSceneUtils.clear_children(_row)
	_empty_label.visible = session_service.cafe_state.plated_pastries.is_empty()
	for table_index in range(session_service.cafe_state.plated_pastries.size()):
		var pastry: PastryInstance = session_service.cafe_state.plated_pastries[table_index]
		var interactable: bool = interaction_state.is_zone_targetable(&"table", table_index) or interaction_state.is_target_selected(&"table", table_index)
		var card: ZoneItemCardView = _instantiate_item_card()
		card.configure(
			UiTextureLibrary.pastry_texture(pastry),
			pastry.get_display_name(),
			UiTextFormatter.describe_pastry(pastry),
			interactable,
			interaction_state.is_target_selected(&"table", table_index),
			interaction_state.is_zone_targetable(&"table", table_index)
		)
		var item_index: int = table_index
		card.action_requested.connect(func() -> void:
			table_item_requested.emit(item_index)
		)
		_row.add_child(card)

func _instantiate_item_card() -> ZoneItemCardView:
	var node: Node = UiSceneUtils.instantiate_required(item_card_scene, "TableZoneView.item_card_scene")
	var card: ZoneItemCardView = node as ZoneItemCardView
	assert(card != null, "TableZoneView.item_card_scene must instantiate ZoneItemCardView.")
	return card

func get_pastry_card_control(item_index: int) -> Control:
	if item_index < 0 or item_index >= _row.get_child_count():
		return null
	return _row.get_child(item_index) as Control
