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
	# Treat compact / medium / wide as separate compositions.
	# For future tuning, keep most changes inside the bucket values below instead of
	# scattering new pixel constants deeper into the rect math.
	var layout_mode: StringName = &"wide"
	if resolved_size.x < 1240.0 or resolved_size.y < 720.0:
		layout_mode = &"compact"
	elif resolved_size.x < 1660.0 or resolved_size.y < 940.0:
		layout_mode = &"medium"
	var margin: float = 28.0
	var support_width: float = 180.0
	var support_height: float = 94.0
	var counter_surface_ratio: float = 0.33
	var counter_surface_height_ratio: float = 0.106
	var customer_top_padding: float = 18.0
	var customer_height_bonus: float = 38.0
	var board_gap: float = 28.0
	var board_side_padding: float = 48.0
	var pile_width: float = 92.0
	var pile_height: float = 112.0
	var resource_width: float = 152.0
	var resource_height: float = 164.0
	var end_turn_width: float = 230.0
	var end_turn_height: float = 78.0
	var footer_top_ratio: float = 0.57
	var hand_overlap: float = 18.0
	var station_bottom_clearance: float = 34.0
	var station_top_ratio: float = 0.01
	var station_height_ratio: float = 0.68
	var station_height_min: float = 236.0
	var station_height_max: float = 404.0
	var hand_card_width: float = 220.0
	var hand_card_height: float = 298.0
	var hand_min_spacing: float = 36.0
	var hand_ideal_spacing: float = 120.0
	var hand_curve_depth: float = 22.0
	var hand_rotation_max: float = 7.2
	var hand_selected_lift: float = 42.0
	var hand_hover_lift: float = 28.0
	var hand_bottom_padding: float = 16.0
	var hand_min_width: float = 360.0
	var station_body_min_height: float = 168.0
	var support_bottom_lift: float = 0.0
	match layout_mode:
		&"compact":
			margin = 12.0
			support_width = 112.0
			support_height = 80.0
			counter_surface_ratio = 0.35
			counter_surface_height_ratio = 0.088
			customer_top_padding = 6.0
			customer_height_bonus = 4.0
			board_gap = 10.0
			board_side_padding = 12.0
			pile_width = 64.0
			pile_height = 78.0
			resource_width = 114.0
			resource_height = 122.0
			end_turn_width = 158.0
			end_turn_height = 52.0
			footer_top_ratio = 0.42
			hand_overlap = 6.0
			station_bottom_clearance = 38.0
			station_top_ratio = 0.04
			station_height_ratio = 0.52
			station_height_min = 154.0
			station_height_max = 222.0
			hand_card_width = 146.0
			hand_card_height = 202.0
			hand_min_spacing = 18.0
			hand_ideal_spacing = 46.0
			hand_curve_depth = 8.0
			hand_rotation_max = 3.0
			hand_selected_lift = 16.0
			hand_hover_lift = 10.0
			hand_bottom_padding = 8.0
			hand_min_width = 272.0
			station_body_min_height = 132.0
			support_bottom_lift = 26.0
		&"medium":
			margin = 16.0
			support_width = 132.0
			support_height = 84.0
			counter_surface_ratio = 0.34
			counter_surface_height_ratio = 0.092
			customer_top_padding = 8.0
			customer_height_bonus = 10.0
			board_gap = 14.0
			board_side_padding = 20.0
			pile_width = 72.0
			pile_height = 90.0
			resource_width = 126.0
			resource_height = 134.0
			end_turn_width = 176.0
			end_turn_height = 60.0
			footer_top_ratio = 0.46
			hand_overlap = 10.0
			station_bottom_clearance = 32.0
			station_top_ratio = 0.03
			station_height_ratio = 0.56
			station_height_min = 176.0
			station_height_max = 270.0
			hand_card_width = 166.0
			hand_card_height = 228.0
			hand_min_spacing = 22.0
			hand_ideal_spacing = 58.0
			hand_curve_depth = 10.0
			hand_rotation_max = 3.8
			hand_selected_lift = 20.0
			hand_hover_lift = 14.0
			hand_bottom_padding = 10.0
			hand_min_width = 308.0
			station_body_min_height = 148.0
			support_bottom_lift = 18.0
		_:
			margin = 28.0
			support_width = 180.0
			support_height = 94.0
			counter_surface_ratio = 0.33
			counter_surface_height_ratio = 0.106
			customer_top_padding = 18.0
			customer_height_bonus = 38.0
			board_gap = 28.0
			board_side_padding = 48.0
			pile_width = 92.0
			pile_height = 112.0
			resource_width = 152.0
			resource_height = 164.0
			end_turn_width = 230.0
			end_turn_height = 78.0
			footer_top_ratio = 0.57
			hand_overlap = 18.0
			station_bottom_clearance = 34.0
			station_top_ratio = 0.01
			station_height_ratio = 0.68
			station_height_min = 236.0
			station_height_max = 404.0
			hand_card_width = 282.0
			hand_card_height = 384.0
			hand_min_spacing = 46.0
			hand_ideal_spacing = 168.0
			hand_curve_depth = 28.0
			hand_rotation_max = 8.8
			hand_selected_lift = 56.0
			hand_hover_lift = 34.0
			hand_bottom_padding = 16.0
			hand_min_width = 520.0
			station_body_min_height = 176.0
			support_bottom_lift = 8.0
	var counter_surface_top: float = resolved_size.y * counter_surface_ratio
	var counter_surface_height: float = clampf(resolved_size.y * counter_surface_height_ratio, 64.0, 112.0)
	var counter_front_top: float = counter_surface_top + counter_surface_height - 6.0
	var counter_front_height: float = resolved_size.y - counter_front_top
	var stage_width: float = resolved_size.x - margin * 2.0
	var customer_x: float = margin + support_width * 0.45
	var customer_top: float = margin + customer_top_padding
	var customer_width: float = resolved_size.x - customer_x - margin
	var customer_height: float = counter_surface_top - customer_top + customer_height_bonus
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
	var deck_rect: Rect2 = Rect2(
		Vector2(margin + 4.0, resolved_size.y - pile_height - margin - support_bottom_lift),
		Vector2(pile_width, pile_height)
	)
	var resource_rect: Rect2 = Rect2(
		Vector2(deck_rect.position.x + deck_rect.size.x + lerpf(24.0, 18.0, compactness), resolved_size.y - resource_height - margin - 6.0 - support_bottom_lift),
		Vector2(resource_width, resource_height)
	)
	var discard_rect: Rect2 = Rect2(
		Vector2(resolved_size.x - margin - pile_width - 4.0, resolved_size.y - pile_height - margin - support_bottom_lift),
		Vector2(pile_width, pile_height)
	)
	var end_turn_rect: Rect2 = Rect2(
		Vector2(resolved_size.x - margin - end_turn_width, resolved_size.y - end_turn_height - margin - 8.0 - support_bottom_lift),
		Vector2(end_turn_width, end_turn_height)
	)
	var discard_gap: float = 12.0 if layout_mode == &"compact" else 16.0
	var discard_bottom: float = minf(
		resolved_size.y - margin,
		end_turn_rect.position.y - discard_gap
	)
	discard_rect.position.y = discard_bottom - discard_rect.size.y
	var footer_top: float = counter_front_top + counter_front_height * footer_top_ratio
	var hand_top: float = footer_top - hand_overlap
	# Board height is solved from the remaining room above the hand band. If something
	# overlaps in compact sizes, adjust footer/hand/support values first, not the station
	# rects below.
	var station_bottom: float = hand_top - station_bottom_clearance
	var station_top: float = counter_surface_top + counter_surface_height * station_top_ratio
	var desired_station_height: float = clampf(counter_front_height * station_height_ratio, station_height_min, station_height_max)
	var station_height: float = minf(desired_station_height, maxf(station_height_min, station_bottom - station_top))
	var oven_top: float = station_bottom - station_height
	var prep_top: float = oven_top + clampf(station_height * 0.06, 10.0, 18.0)
	var table_top: float = oven_top + clampf(station_height * 0.04, 8.0, 16.0)
	var prep_rect: Rect2 = Rect2(
		Vector2(stations_x, prep_top),
		Vector2(prep_width, maxf(station_body_min_height, station_bottom - prep_top))
	)
	var oven_rect: Rect2 = Rect2(
		Vector2(prep_rect.position.x + prep_rect.size.x + board_gap, oven_top),
		Vector2(oven_width, station_height)
	)
	var table_rect: Rect2 = Rect2(
		Vector2(oven_rect.position.x + oven_rect.size.x + board_gap, table_top),
		Vector2(table_width, maxf(station_body_min_height, station_bottom - table_top))
	)
	var hand_height: float = resolved_size.y - hand_top - margin * 0.22
	var hand_left_clear: float = resource_rect.position.x + resource_rect.size.x + lerpf(26.0, 16.0, compactness)
	var hand_right_clear: float = maxf(discard_rect.size.x + margin + 32.0, end_turn_width + margin + 28.0)
	var hand_rect: Rect2 = Rect2(
		Vector2(hand_left_clear, hand_top),
		Vector2(maxf(hand_min_width, resolved_size.x - hand_left_clear - hand_right_clear), hand_height)
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
		"hand_card_width": hand_card_width,
		"hand_card_height": hand_card_height,
		"hand_min_spacing": hand_min_spacing,
		"hand_ideal_spacing": hand_ideal_spacing,
		"hand_curve_depth": hand_curve_depth,
		"hand_rotation_max": hand_rotation_max,
		"hand_selected_lift": hand_selected_lift,
		"hand_hover_lift": hand_hover_lift,
		"hand_bottom_padding": hand_bottom_padding,
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
