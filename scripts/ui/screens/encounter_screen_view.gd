class_name EncounterScreenView
extends Control

signal end_turn_requested()
signal play_card_requested(card_index: int)
signal focus_customer_requested(customer_index: int)
signal customer_item_requested(customer_index: int)
signal prep_item_requested(item_index: int)
signal oven_item_requested(slot_index: int)
signal table_item_requested(item_index: int)

@onready var _background_art: TextureRect = $BackgroundArt
@onready var _backdrop_tint: ColorRect = $BackdropTint
@onready var _counter_surface: PanelContainer = $CounterSurface
@onready var _counter_front: PanelContainer = $CounterFront
@onready var _counter_line: ColorRect = $CounterLine
@onready var _table_counter_vertical: ColorRect = $TableCounterVertical
@onready var _table_counter_bottom: ColorRect = $TableCounterBottom
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

var _layout_profile: Dictionary = {}

func _ready() -> void:
	_background_art.texture = UiTextureLibrary.background_texture()
	_effect_overlay.set_anchor_provider(Callable(self, "_anchor_rect_for_feedback"))
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

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_RESIZED:
		call_deferred("_layout_stage")

func configure_event_bus(event_bus: EventBus) -> void:
	_effect_overlay.configure(event_bus)

func render(session_service: SessionService, interaction_state: EncounterInteractionState) -> void:
	_layout_stage()
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

func _layout_stage() -> void:
	if not is_node_ready():
		return
	_layout_profile = _build_layout_profile(size if size != Vector2.ZERO else get_viewport_rect().size)
	_apply_rect(_background_art, _layout_profile["background_rect"])
	_apply_rect(_backdrop_tint, _layout_profile["background_rect"])
	_apply_rect(_counter_surface, _layout_profile["counter_surface_rect"])
	_apply_rect(_counter_front, _layout_profile["counter_front_rect"])
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
	_apply_rect(_counter_line, _layout_profile["counter_line_rect"])
	_apply_rect(_table_counter_vertical, _layout_profile["table_counter_vertical_rect"])
	_apply_rect(_table_counter_bottom, _layout_profile["table_counter_bottom_rect"])

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
	var resolved_size: Vector2 = Vector2(maxf(960.0, viewport_size.x), maxf(600.0, viewport_size.y))
	var width_pressure: float = clampf((1480.0 - resolved_size.x) / 540.0, 0.0, 1.0)
	var height_pressure: float = clampf((900.0 - resolved_size.y) / 260.0, 0.0, 1.0)
	var compactness: float = clampf(maxf(width_pressure, height_pressure), 0.0, 1.0)
	var margin: float = lerpf(28.0, 16.0, compactness)
	var support_width: float = clampf(resolved_size.x * lerpf(0.15, 0.18, compactness), 150.0, 220.0)
	var support_height: float = clampf(resolved_size.y * lerpf(0.11, 0.13, compactness), 70.0, 104.0)
	var counter_surface_top: float = resolved_size.y * lerpf(0.37, 0.40, compactness)
	var counter_surface_height: float = clampf(resolved_size.y * lerpf(0.11, 0.095, compactness), 64.0, 102.0)
	var counter_front_top: float = counter_surface_top + counter_surface_height - 6.0
	var counter_front_height: float = resolved_size.y - counter_front_top
	var stage_width: float = resolved_size.x - margin * 2.0
	var customer_x: float = margin + support_width * 0.45
	var customer_top: float = margin + 8.0
	var customer_width: float = resolved_size.x - customer_x - margin
	var customer_height: float = counter_surface_top - customer_top + 26.0
	var board_gap: float = lerpf(26.0, 14.0, compactness)
	var board_side_padding: float = lerpf(40.0, 18.0, compactness)
	var station_inner_width: float = stage_width - board_side_padding * 2.0
	var prep_width: float = station_inner_width * 0.29
	var oven_width: float = station_inner_width * 0.34
	var table_width: float = station_inner_width * 0.29
	var width_sum: float = prep_width + oven_width + table_width + board_gap * 2.0
	if width_sum > station_inner_width:
		var width_scale: float = (station_inner_width - board_gap * 2.0) / maxf(1.0, prep_width + oven_width + table_width)
		prep_width *= width_scale
		oven_width *= width_scale
		table_width *= width_scale
	var stations_x: float = margin + (stage_width - (prep_width + oven_width + table_width + board_gap * 2.0)) * 0.5
	var station_top: float = counter_surface_top + counter_surface_height * 0.04
	var station_height: float = clampf(counter_front_height * lerpf(0.46, 0.38, compactness), 196.0, 294.0)
	var prep_rect: Rect2 = Rect2(
		Vector2(stations_x, station_top + station_height * 0.06),
		Vector2(prep_width, station_height * 0.86)
	)
	var oven_rect: Rect2 = Rect2(
		Vector2(prep_rect.position.x + prep_rect.size.x + board_gap, station_top),
		Vector2(oven_width, station_height)
	)
	var table_rect: Rect2 = Rect2(
		Vector2(oven_rect.position.x + oven_rect.size.x + board_gap, station_top + station_height * 0.04),
		Vector2(table_width, station_height * 0.88)
	)
	var pile_width: float = lerpf(86.0, 70.0, compactness)
	var pile_height: float = lerpf(104.0, 88.0, compactness)
	var deck_rect: Rect2 = Rect2(
		Vector2(margin + 4.0, resolved_size.y - pile_height - margin),
		Vector2(pile_width, pile_height)
	)
	var footer_top: float = counter_front_top + counter_front_height * lerpf(0.38, 0.42, compactness)
	var hand_top: float = footer_top - lerpf(38.0, 22.0, compactness)
	var resource_width: float = lerpf(142.0, 124.0, compactness)
	var resource_height: float = lerpf(146.0, 128.0, compactness)
	var resource_rect: Rect2 = Rect2(
		Vector2(deck_rect.position.x + deck_rect.size.x + 24.0, resolved_size.y - resource_height - margin - 6.0),
		Vector2(resource_width, resource_height)
	)
	var discard_rect: Rect2 = Rect2(
		Vector2(resolved_size.x - margin - pile_width - 4.0, resolved_size.y - pile_height - margin),
		Vector2(pile_width, pile_height)
	)
	var end_turn_width: float = lerpf(214.0, 176.0, compactness)
	var end_turn_height: float = lerpf(74.0, 60.0, compactness)
	var end_turn_rect: Rect2 = Rect2(
		Vector2(resolved_size.x - margin - end_turn_width, resolved_size.y - end_turn_height - margin - 8.0),
		Vector2(end_turn_width, end_turn_height)
	)
	var hand_height: float = resolved_size.y - hand_top - margin * 0.22
	var hand_left_clear: float = resource_rect.position.x + resource_rect.size.x + lerpf(26.0, 16.0, compactness)
	var hand_right_clear: float = maxf(discard_rect.size.x + margin + 32.0, end_turn_width + margin + 28.0)
	var hand_rect: Rect2 = Rect2(
		Vector2(hand_left_clear, hand_top),
		Vector2(maxf(360.0, resolved_size.x - hand_left_clear - hand_right_clear), hand_height)
	)
	var prompt_width: float = clampf(resolved_size.x * lerpf(0.28, 0.34, compactness), 260.0, 420.0)
	var prompt_height: float = lerpf(64.0, 54.0, compactness)
	var prompt_rect: Rect2 = Rect2(
		Vector2((resolved_size.x - prompt_width) * 0.5, counter_front_top + 18.0),
		Vector2(prompt_width, prompt_height)
	)
	var prep_oven_divider_x: float = prep_rect.position.x + prep_rect.size.x + board_gap * 0.48
	var oven_table_divider_x: float = oven_rect.position.x + oven_rect.size.x + board_gap * 0.48
	var divider_y: float = counter_surface_top + 16.0
	var divider_height: float = station_height * 0.92
	var profile: Dictionary = {
		"background_rect": Rect2(Vector2.ZERO, resolved_size),
		"counter_surface_rect": Rect2(Vector2(margin, counter_surface_top), Vector2(stage_width, counter_surface_height)),
		"counter_front_rect": Rect2(Vector2(margin, counter_front_top), Vector2(stage_width, counter_front_height)),
		"support_hud_rect": Rect2(Vector2(margin, margin), Vector2(support_width, support_height)),
		"customer_lane_rect": Rect2(Vector2(customer_x, customer_top), Vector2(customer_width, customer_height)),
		"prep_rect": prep_rect,
		"oven_rect": oven_rect,
		"table_rect": table_rect,
		"deck_rect": deck_rect,
		"discard_rect": discard_rect,
		"prompt_rect": prompt_rect,
		"resource_rect": resource_rect,
		"hand_rect": hand_rect,
		"end_turn_rect": end_turn_rect,
		"counter_line_rect": Rect2(Vector2(margin, counter_surface_top), Vector2(stage_width, 4.0)),
		"table_counter_vertical_rect": Rect2(Vector2(prep_oven_divider_x, divider_y), Vector2(4.0, divider_height)),
		"table_counter_bottom_rect": Rect2(Vector2(oven_table_divider_x, divider_y), Vector2(4.0, divider_height)),
		"hand_card_width": lerpf(204.0, 160.0, compactness),
		"hand_card_height": lerpf(282.0, 224.0, compactness),
		"hand_min_spacing": lerpf(42.0, 28.0, compactness),
		"hand_ideal_spacing": lerpf(126.0, 78.0, compactness),
		"hand_curve_depth": lerpf(30.0, 18.0, compactness),
		"hand_rotation_max": lerpf(10.0, 5.5, compactness),
		"hand_selected_lift": lerpf(54.0, 34.0, compactness),
		"hand_hover_lift": lerpf(32.0, 22.0, compactness),
		"hand_bottom_padding": lerpf(10.0, 6.0, compactness),
	}
	return profile

func _apply_rect(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size

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
