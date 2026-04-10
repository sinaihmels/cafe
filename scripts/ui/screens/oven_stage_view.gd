class_name OvenStageView
extends KitchenStageAreaView

signal oven_item_requested(slot_index: int)

func _ready() -> void:
	setup_stage()
	var oven_view: OvenZoneView = _oven_view()
	assert(oven_view != null, "OvenStageView.zone_scene must instantiate OvenZoneView.")
	oven_view.oven_item_requested.connect(func(slot_index: int) -> void:
		oven_item_requested.emit(slot_index)
	)

func render(session_service: SessionService, interaction_state: EncounterInteractionState) -> void:
	var resolved_base_texture: Texture2D = base_texture if base_texture != null else UiTextureLibrary.oven_stage_texture(session_service.cafe_state)
	var resolved_overlay_texture: Texture2D = overlay_texture if overlay_texture != null else UiTextureLibrary.oven_stage_overlay_texture(session_service.cafe_state)
	set_runtime_textures(resolved_base_texture, resolved_overlay_texture)
	var oven_view: OvenZoneView = _oven_view()
	if oven_view != null:
		oven_view.render(session_service, interaction_state)

func get_pastry_card_control(item_index: int) -> Control:
	var oven_view: OvenZoneView = _oven_view()
	if oven_view == null:
		return null
	return oven_view.get_pastry_card_control(item_index)

func _oven_view() -> OvenZoneView:
	return get_zone_view() as OvenZoneView
