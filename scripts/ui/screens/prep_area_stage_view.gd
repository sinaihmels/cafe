class_name PrepAreaStageView
extends KitchenStageAreaView

signal prep_item_requested(item_index: int)

func _ready() -> void:
	setup_stage()
	var prep_view: PrepZoneView = _prep_view()
	assert(prep_view != null, "PrepAreaStageView.zone_scene must instantiate PrepZoneView.")
	prep_view.prep_item_requested.connect(func(item_index: int) -> void:
		prep_item_requested.emit(item_index)
	)

func render(session_service: SessionService, interaction_state: EncounterInteractionState) -> void:
	var resolved_base_texture: Texture2D = base_texture if base_texture != null else UiTextureLibrary.prep_area_texture(session_service.cafe_state)
	var resolved_overlay_texture: Texture2D = overlay_texture if overlay_texture != null else UiTextureLibrary.prep_area_overlay_texture(session_service.cafe_state)
	set_runtime_textures(resolved_base_texture, resolved_overlay_texture)
	var prep_view: PrepZoneView = _prep_view()
	if prep_view != null:
		prep_view.render(session_service, interaction_state)

func get_pastry_card_control(item_index: int) -> Control:
	var prep_view: PrepZoneView = _prep_view()
	if prep_view == null:
		return null
	return prep_view.get_pastry_card_control(item_index)

func _prep_view() -> PrepZoneView:
	return get_zone_view() as PrepZoneView
