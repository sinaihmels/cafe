@tool
class_name EncounterScreenView
extends Control

signal end_turn_requested()
signal play_card_requested(card_index: int)
signal focus_customer_requested(customer_index: int)
signal customer_item_requested(customer_index: int)
signal prep_item_requested(item_index: int)
signal oven_item_requested(slot_index: int)
signal table_item_requested(item_index: int)
signal dialogue_continue_requested()
signal dialogue_response_requested(response_index: int)

@onready var _background_art: TextureRect = $BackgroundArt
@onready var _counter_view: EncounterCounterView = $CounterView
@onready var _hud_view: EncounterHudView = $SupportHudView
@onready var _customer_lane: CustomerLaneView = $CustomerLaneView
@onready var _prep_stage: PrepAreaStageView = $PrepStageView
@onready var _oven_stage: OvenStageView = $OvenStageView
@onready var _table_stage: FinishedPastryStageView = $TableStageView
@onready var _deck_pile: PanelContainer = $DeckPile
@onready var _deck_pile_count: Label = $DeckPile/DeckPileMargin/DeckPileBody/DeckPileCount
@onready var _discard_pile: PanelContainer = $DiscardPile
@onready var _discard_pile_count: Label = $DiscardPile/DiscardPileMargin/DiscardPileBody/DiscardPileCount
@onready var _prompt_view: EncounterPromptView = $PromptView
@onready var _resources_view: EncounterResourcesView = $ResourcesView
@onready var _hand_fan: HandFanView = $HandFanView
@onready var _end_turn_button: Button = $EndTurnButton
@onready var _effect_overlay: EncounterEffectOverlayView = $EncounterEffectOverlayView
@onready var _dialogue_overlay: EncounterDialogueOverlayView = $EncounterDialogueOverlayView

@export_group("Layout Scale")
@export var fallback_reference_size: Vector2 = Vector2(1152.0, 648.0)
@export_range(0.1, 2.0, 0.01) var hand_scale_min: float = 0.72
@export_range(0.1, 3.0, 0.01) var hand_scale_max: float = 1.3

var _layout_profile: Dictionary = {}
var _base_rects: Dictionary = {}
var _layout_reference_size: Vector2 = Vector2.ZERO
var _base_hand_metrics: Dictionary = {}
var _editor_refresh_signature: Array = []

func _ready() -> void:
	_pin_overlay_layers()
	if _background_art.texture == null:
		_background_art.texture = UiTextureLibrary.background_texture()
	if Engine.is_editor_hint():
		_editor_refresh_signature = _make_editor_refresh_signature()
		set_process(true)
		_render_editor_preview()
		return
	_capture_editor_layout()
	_effect_overlay.set_anchor_provider(Callable(self, "_anchor_rect_for_feedback"))
	_dialogue_overlay.set_anchor_provider(Callable(self, "_anchor_rect_for_dialogue"))
	_dialogue_overlay.continue_requested.connect(func() -> void:
		dialogue_continue_requested.emit()
	)
	_dialogue_overlay.response_requested.connect(func(response_index: int) -> void:
		dialogue_response_requested.emit(response_index)
	)
	_end_turn_button.pressed.connect(func() -> void: end_turn_requested.emit())
	_customer_lane.focus_customer_requested.connect(func(customer_index: int) -> void:
		focus_customer_requested.emit(customer_index)
	)
	_customer_lane.customer_target_requested.connect(func(customer_index: int) -> void:
		customer_item_requested.emit(customer_index)
	)
	_prep_stage.prep_item_requested.connect(func(item_index: int) -> void:
		prep_item_requested.emit(item_index)
	)
	_oven_stage.oven_item_requested.connect(func(slot_index: int) -> void:
		oven_item_requested.emit(slot_index)
	)
	_table_stage.table_item_requested.connect(func(item_index: int) -> void:
		table_item_requested.emit(item_index)
	)
	_hand_fan.play_card_requested.connect(func(card_index: int) -> void:
		play_card_requested.emit(card_index)
	)
	call_deferred("_layout_stage")

func _pin_overlay_layers() -> void:
	# Keep transient overlays as the final siblings so they win both draw order and UI hit testing.
	move_child(_effect_overlay, get_child_count() - 1)
	move_child(_dialogue_overlay, get_child_count() - 1)

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if Engine.is_editor_hint():
		if what == NOTIFICATION_RESIZED:
			call_deferred("_refresh_editor_preview")
		return
	if what == NOTIFICATION_RESIZED:
		call_deferred("_layout_stage")

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or not is_node_ready():
		return
	var signature: Array = _make_editor_refresh_signature()
	if signature == _editor_refresh_signature:
		return
	_editor_refresh_signature = signature
	_refresh_editor_preview()

func configure_event_bus(event_bus: EventBus) -> void:
	_effect_overlay.configure(event_bus)

func render(
	session_service: SessionService,
	interaction_state: EncounterInteractionState,
	dialogue_state: DialoguePresentationState = null
) -> void:
	if not Engine.is_editor_hint():
		_layout_stage()
	var resolved_dialogue_state: DialoguePresentationState = dialogue_state if dialogue_state != null else DialoguePresentationState.new()
	_prompt_view.render(interaction_state.pending_prompt)
	_hud_view.render(session_service)
	_customer_lane.render(session_service, interaction_state)
	_prep_stage.render(session_service, interaction_state)
	_oven_stage.render(session_service, interaction_state)
	_table_stage.render(session_service, interaction_state)
	_deck_pile_count.text = str(session_service.deck_state.draw_pile.size())
	_discard_pile_count.text = str(session_service.deck_state.discard_pile.size())
	_resources_view.render(session_service)
	_apply_hand_metrics()
	_hand_fan.render(session_service, interaction_state)
	if Engine.is_editor_hint():
		_dialogue_overlay.visible = false
	else:
		_dialogue_overlay.render(resolved_dialogue_state)

func render_editor_preview() -> void:
	_render_editor_preview()

func _layout_stage() -> void:
	if not is_node_ready():
		return
	_layout_profile = _build_layout_profile(size if size != Vector2.ZERO else get_viewport_rect().size)
	_apply_rect(_background_art, _layout_profile["customer_backdrop_rect"])
	_apply_rect(_counter_view, _layout_profile["counter_rect"])
	_apply_rect(_hud_view, _layout_profile["support_hud_rect"])
	_apply_rect(_customer_lane, _layout_profile["customer_lane_rect"])
	_apply_rect(_prep_stage, _layout_profile["prep_rect"])
	_apply_rect(_oven_stage, _layout_profile["oven_rect"])
	_apply_rect(_table_stage, _layout_profile["table_rect"])
	_apply_rect(_deck_pile, _layout_profile["deck_rect"])
	_apply_rect(_discard_pile, _layout_profile["discard_rect"])
	_apply_rect(_prompt_view, _layout_profile["prompt_rect"])
	_apply_rect(_resources_view, _layout_profile["resource_rect"])
	_apply_rect(_hand_fan, _layout_profile["hand_rect"])
	_apply_rect(_end_turn_button, _layout_profile["end_turn_rect"])

func _apply_hand_metrics() -> void:
	if _layout_profile.is_empty():
		return
	_hand_fan.configure_layout_metrics(
		_layout_profile["hand_card_width"],
		_layout_profile["hand_card_height"],
		_layout_profile["hand_min_spacing"],
		_layout_profile["hand_ideal_spacing"],
		_layout_profile["hand_curve_depth"],
		_layout_profile["hand_rotation_max"],
		_layout_profile["hand_selected_lift"],
		_layout_profile["hand_hover_lift"],
		_layout_profile["hand_bottom_padding"]
	)

func _build_layout_profile(viewport_size: Vector2) -> Dictionary:
	if _base_rects.is_empty():
		_capture_editor_layout()
	var resolved_size: Vector2 = viewport_size if viewport_size != Vector2.ZERO else _layout_reference_size
	var reference_size: Vector2 = _layout_reference_size if _layout_reference_size != Vector2.ZERO else fallback_reference_size
	var hand_scale: float = clampf(
		minf(resolved_size.x / reference_size.x, resolved_size.y / reference_size.y),
		hand_scale_min,
		hand_scale_max
	)
	var layout_scale: float = minf(
		resolved_size.x / maxf(1.0, reference_size.x),
		resolved_size.y / maxf(1.0, reference_size.y)
	)
	if layout_scale <= 0.0:
		layout_scale = 1.0
	var layout_size: Vector2 = reference_size * layout_scale
	var layout_origin: Vector2 = (resolved_size - layout_size) * 0.5
	var profile: Dictionary = {}
	for key in _base_rects.keys():
		profile[key] = _scaled_rect(_base_rects[key], layout_origin, layout_scale)
	profile["hand_card_width"] = _base_hand_metrics["card_width"] * hand_scale
	profile["hand_card_height"] = _base_hand_metrics["card_height"] * hand_scale
	profile["hand_min_spacing"] = _base_hand_metrics["min_spacing"] * hand_scale
	profile["hand_ideal_spacing"] = _base_hand_metrics["ideal_spacing"] * hand_scale
	profile["hand_curve_depth"] = _base_hand_metrics["curve_depth"] * hand_scale
	profile["hand_rotation_max"] = _base_hand_metrics["rotation_max"] as float
	profile["hand_selected_lift"] = _base_hand_metrics["selected_lift"] * hand_scale
	profile["hand_hover_lift"] = _base_hand_metrics["hover_lift"] * hand_scale
	profile["hand_bottom_padding"] = _base_hand_metrics["bottom_padding"] * hand_scale
	return profile

func _capture_editor_layout() -> void:
	var rect_sources: Dictionary = {
		"customer_backdrop_rect": _background_art,
		"counter_rect": _counter_view,
		"support_hud_rect": _hud_view,
		"customer_lane_rect": _customer_lane,
		"prep_rect": _prep_stage,
		"oven_rect": _oven_stage,
		"table_rect": _table_stage,
		"deck_rect": _deck_pile,
		"discard_rect": _discard_pile,
		"prompt_rect": _prompt_view,
		"resource_rect": _resources_view,
		"hand_rect": _hand_fan,
		"end_turn_rect": _end_turn_button,
	}
	_base_rects.clear()
	var authored_reference_size: Vector2 = fallback_reference_size
	_layout_reference_size = authored_reference_size
	for key in rect_sources.keys():
		var control: Control = rect_sources[key] as Control
		if control == null:
			continue
		var rect: Rect2 = _authored_rect_for(control, authored_reference_size)
		_base_rects[key] = rect
		_layout_reference_size.x = maxf(_layout_reference_size.x, rect.position.x + rect.size.x)
		_layout_reference_size.y = maxf(_layout_reference_size.y, rect.position.y + rect.size.y)
	_base_hand_metrics = {
		"card_width": _hand_fan.card_width,
		"card_height": _hand_fan.card_height,
		"min_spacing": _hand_fan.min_spacing,
		"ideal_spacing": _hand_fan.ideal_spacing,
		"curve_depth": _hand_fan.curve_depth,
		"rotation_max": _hand_fan.rotation_max_degrees,
		"selected_lift": _hand_fan.selected_lift,
		"hover_lift": _hand_fan.hover_lift,
		"bottom_padding": _hand_fan.bottom_padding,
	}

func _authored_rect_for(control: Control, reference_size: Vector2) -> Rect2:
	var left: float = reference_size.x * control.anchor_left + control.offset_left
	var top: float = reference_size.y * control.anchor_top + control.offset_top
	var right: float = reference_size.x * control.anchor_right + control.offset_right
	var bottom: float = reference_size.y * control.anchor_bottom + control.offset_bottom
	return Rect2(Vector2(left, top), Vector2(right - left, bottom - top))

func _make_editor_refresh_signature() -> Array:
	return [
		fallback_reference_size,
		hand_scale_min,
		hand_scale_max,
	]

func _refresh_editor_preview() -> void:
	if not Engine.is_editor_hint() or not is_node_ready():
		return
	_layout_profile.clear()
	_render_editor_preview()

func _scaled_rect(rect: Rect2, origin: Vector2, scale: float) -> Rect2:
	return Rect2(origin + rect.position * scale, rect.size * scale)

func _apply_rect(control: Control, rect: Rect2) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y

func _anchor_rect_for_feedback(feedback: PastryFeedbackEvent) -> Rect2:
	if feedback == null:
		return Rect2()
	var card_control: Control = null
	match feedback.zone:
		&"prep":
			card_control = _prep_stage.get_pastry_card_control(feedback.index)
		&"table":
			card_control = _table_stage.get_pastry_card_control(feedback.index)
		&"oven":
			card_control = _oven_stage.get_pastry_card_control(feedback.index)
		_:
			card_control = null
	if card_control == null:
		return Rect2()
	return Rect2(card_control.global_position - global_position, card_control.size)

func _anchor_rect_for_dialogue(customer_index: int) -> Rect2:
	var customer_control: Control = _customer_lane.get_customer_spot_control(customer_index)
	if customer_control == null:
		return Rect2()
	return Rect2(customer_control.global_position - global_position, customer_control.size)

func _render_editor_preview() -> void:
	if not Engine.is_editor_hint():
		return
	var preview_session: SessionService = EncounterEditorPreview.build_session()
	var preview_interaction_state: EncounterInteractionState = EncounterEditorPreview.build_interaction_state(preview_session)
	var preview_dialogue_state: DialoguePresentationState = EncounterEditorPreview.build_dialogue_state()
	render(preview_session, preview_interaction_state, preview_dialogue_state)
