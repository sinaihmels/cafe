class_name OvenZoneView
extends PanelContainer

signal oven_item_requested(slot_index: int)

@export var item_card_scene: PackedScene

@onready var _subtitle: Label = $OvenMargin/OvenBody/OvenSubtitle
@onready var _row: HBoxContainer = $OvenMargin/OvenBody/OvenArea/OvenRow

func render(session_service: SessionService, interaction_state: EncounterInteractionState) -> void:
	UiSceneUtils.clear_children(_row)
	_subtitle.text = "%d slots" % session_service.cafe_state.oven_slots.size()
	for slot_index in range(session_service.cafe_state.oven_slots.size()):
		var slot: OvenSlotState = session_service.cafe_state.oven_slots[slot_index]
		var card: ZoneItemCardView = _instantiate_item_card()
		if slot.item == null:
			card.configure(UiTextureLibrary.item_texture(null), "Slot %d" % (slot_index + 1), "Empty", false, false, false)
			_row.add_child(card)
			continue
		var ready: bool = slot.stage == &"ready" or (slot.stage == &"" and slot.remaining_turns <= 0)
		var interactable: bool = interaction_state.is_zone_targetable(&"oven", slot_index) or ready or interaction_state.is_target_selected(&"oven", slot_index)
		card.configure(
			UiTextureLibrary.item_texture(slot.item.item_def),
			slot.item.get_display_name(),
			_status_text(slot),
			interactable,
			interaction_state.is_target_selected(&"oven", slot_index),
			interaction_state.is_zone_targetable(&"oven", slot_index) or ready
		)
		var oven_index: int = slot_index
		card.action_requested.connect(func() -> void:
			oven_item_requested.emit(oven_index)
		)
		_row.add_child(card)

func _status_text(slot: OvenSlotState) -> String:
	var ready: bool = slot.stage == &"ready" or (slot.stage == &"" and slot.remaining_turns <= 0)
	if slot.stage == &"proofing":
		return "Proofing (%d turn left)" % max(1, slot.remaining_turns)
	if slot.stage == &"proofed":
		return "Proofed"
	if slot.stage == &"baking":
		return "Baking (%d turn left)" % max(1, slot.remaining_turns)
	if ready:
		return "Ready"
	if slot.remaining_turns > 0:
		return "%d turn left" % slot.remaining_turns
	return "In Oven"

func _instantiate_item_card() -> ZoneItemCardView:
	var node: Node = UiSceneUtils.instantiate_required(item_card_scene, "OvenZoneView.item_card_scene")
	var card: ZoneItemCardView = node as ZoneItemCardView
	assert(card != null, "OvenZoneView.item_card_scene must instantiate ZoneItemCardView.")
	return card
