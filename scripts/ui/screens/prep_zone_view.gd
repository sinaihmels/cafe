class_name PrepZoneView
extends PanelContainer

signal prep_item_requested(item_index: int)

@export var item_card_scene: PackedScene

@onready var _subtitle: Label = $PrepMargin/PrepBody/PrepSubtitle
@onready var _grid: GridContainer = $PrepMargin/PrepBody/PrepArea/PrepGrid
@onready var _empty_label: Label = $PrepMargin/PrepBody/PrepArea/PrepEmptyLabel
@onready var _energy_value: Label = $PrepMargin/PrepBody/PrepArea/PrepEnergyCoin/PrepEnergyMargin/PrepEnergyBody/PrepEnergyValue

func render(session_service: SessionService, interaction_state: EncounterInteractionState) -> void:
	UiSceneUtils.clear_children(_grid)
	_subtitle.text = "%d / %d items" % [session_service.cafe_state.prep_items.size(), session_service.cafe_state.prep_space_capacity]
	_empty_label.visible = session_service.cafe_state.prep_items.is_empty()
	_energy_value.text = str(session_service.player_state.energy)
	for prep_index in range(session_service.cafe_state.prep_items.size()):
		var prep_item: ItemInstance = session_service.cafe_state.prep_items[prep_index]
		var interactable: bool = interaction_state.is_zone_targetable(&"prep", prep_index) or interaction_state.is_target_selected(&"prep", prep_index)
		var selected: bool = interaction_state.is_target_selected(&"prep", prep_index)
		var targetable: bool = interaction_state.is_zone_targetable(&"prep", prep_index)
		var card: ZoneItemCardView = _instantiate_item_card()
		card.configure(
			UiTextureLibrary.item_texture(prep_item.item_def),
			prep_item.get_display_name(),
			"Q%d | %s" % [prep_item.quality, UiTextFormatter.join_packed(prep_item.get_all_tags())],
			interactable,
			selected,
			targetable
		)
		var item_index: int = prep_index
		card.action_requested.connect(func() -> void:
			prep_item_requested.emit(item_index)
		)
		_grid.add_child(card)

func _instantiate_item_card() -> ZoneItemCardView:
	var node: Node = UiSceneUtils.instantiate_required(item_card_scene, "PrepZoneView.item_card_scene")
	var card: ZoneItemCardView = node as ZoneItemCardView
	assert(card != null, "PrepZoneView.item_card_scene must instantiate ZoneItemCardView.")
	return card
