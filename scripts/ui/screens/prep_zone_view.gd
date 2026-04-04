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
	_subtitle.text = "1 active pastry"
	_empty_label.visible = session_service.cafe_state.active_pastry == null
	_energy_value.text = str(session_service.player_state.energy)
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
