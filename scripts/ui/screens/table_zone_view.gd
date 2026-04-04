class_name TableZoneView
extends PanelContainer

signal table_item_requested(item_index: int)

@export var item_card_scene: PackedScene

@onready var _subtitle: Label = $TableMargin/TableBody/TableSubtitle
@onready var _row: HBoxContainer = $TableMargin/TableBody/TableArea/TableRow
@onready var _empty_label: Label = $TableMargin/TableBody/TableArea/TableEmptyLabel

func render(session_service: SessionService, interaction_state: EncounterInteractionState) -> void:
	UiSceneUtils.clear_children(_row)
	_subtitle.text = "%d / %d items" % [session_service.cafe_state.table_items.size(), session_service.cafe_state.serving_table_capacity]
	_empty_label.visible = session_service.cafe_state.table_items.is_empty()
	for table_index in range(session_service.cafe_state.table_items.size()):
		var table_item: ItemInstance = session_service.cafe_state.table_items[table_index]
		var interactable: bool = interaction_state.is_zone_targetable(&"table", table_index) or interaction_state.is_target_selected(&"table", table_index)
		var card: ZoneItemCardView = _instantiate_item_card()
		card.configure(
			UiTextureLibrary.item_texture(table_item.item_def),
			table_item.get_display_name(),
			"Q%d | %s" % [table_item.quality, UiTextFormatter.join_packed(table_item.get_all_tags())],
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
