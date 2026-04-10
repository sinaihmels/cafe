class_name FinishedPastryStageView
extends KitchenStageAreaView

signal table_item_requested(item_index: int)

func _ready() -> void:
	setup_stage()
	var table_view: TableZoneView = _table_view()
	assert(table_view != null, "FinishedPastryStageView.zone_scene must instantiate TableZoneView.")
	table_view.table_item_requested.connect(func(item_index: int) -> void:
		table_item_requested.emit(item_index)
	)

func render(session_service: SessionService, interaction_state: EncounterInteractionState) -> void:
	var resolved_base_texture: Texture2D = base_texture if base_texture != null else UiTextureLibrary.finished_pastry_texture(session_service.cafe_state)
	var resolved_overlay_texture: Texture2D = overlay_texture if overlay_texture != null else UiTextureLibrary.finished_pastry_overlay_texture(session_service.cafe_state)
	set_runtime_textures(resolved_base_texture, resolved_overlay_texture)
	var table_view: TableZoneView = _table_view()
	if table_view != null:
		table_view.render(session_service, interaction_state)

func get_pastry_card_control(item_index: int) -> Control:
	var table_view: TableZoneView = _table_view()
	if table_view == null:
		return null
	return table_view.get_pastry_card_control(item_index)

func _table_view() -> TableZoneView:
	return get_zone_view() as TableZoneView
