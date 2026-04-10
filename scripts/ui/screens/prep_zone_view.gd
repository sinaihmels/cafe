class_name PrepZoneView
extends Control

signal prep_item_requested(item_index: int)

@export var item_card_scene: PackedScene

@onready var _grid: GridContainer = $PrepGrid
@onready var _empty_label: Label = $PrepEmptyLabel

func render(session_service: SessionService, interaction_state: EncounterInteractionState) -> void:
	UiSceneUtils.clear_children(_grid)
	_empty_label.visible = session_service.cafe_state.active_pastry == null
	if session_service.cafe_state.active_pastry != null:
		var pastry: PastryInstance = session_service.cafe_state.active_pastry
		var interactable: bool = interaction_state.is_zone_targetable(&"prep", 0) or interaction_state.is_target_selected(&"prep", 0)
		var selected: bool = interaction_state.is_target_selected(&"prep", 0)
		var targetable: bool = interaction_state.is_zone_targetable(&"prep", 0)
		var card: ZoneItemCardView = _instantiate_item_card()
		card.configure(
			UiTextureLibrary.pastry_texture(pastry),
			pastry.get_display_name(),
			UiTextFormatter.describe_pastry(pastry),
			interactable,
			selected,
			targetable
		)
		card.action_requested.connect(func() -> void:
			prep_item_requested.emit(0)
		)
		_grid.add_child(card)

func _instantiate_item_card() -> ZoneItemCardView:
	var node: Node = UiSceneUtils.instantiate_required(item_card_scene, "PrepZoneView.item_card_scene")
	var card: ZoneItemCardView = node as ZoneItemCardView
	assert(card != null, "PrepZoneView.item_card_scene must instantiate ZoneItemCardView.")
	return card

func get_pastry_card_control(item_index: int) -> Control:
	if item_index < 0 or item_index >= _grid.get_child_count():
		return null
	return _grid.get_child(item_index) as Control
