class_name EncounterScreenView
extends Control

signal end_turn_requested()
signal play_card_requested(card_index: int)
signal focus_customer_requested(customer_index: int)
signal customer_item_requested(customer_index: int)
signal prep_item_requested(item_index: int)
signal oven_item_requested(slot_index: int)
signal table_item_requested(item_index: int)

@onready var _hud_view: EncounterHudView = $EncounterRoot/HeaderRow/HudView
@onready var _prompt_view: EncounterPromptView = $EncounterRoot/HeaderRow/PromptView
@onready var _customer_view: CustomerFocusView = $EncounterRoot/HeaderRow/CustomerView
@onready var _prep_view: PrepZoneView = $EncounterRoot/BoardArea/ZonesRow/PrepView
@onready var _oven_view: OvenZoneView = $EncounterRoot/BoardArea/ZonesRow/OvenView
@onready var _table_view: TableZoneView = $EncounterRoot/BoardArea/ZonesRow/TableView
@onready var _deck_pile_count: Label = $EncounterRoot/BoardArea/DeckPile/DeckPileMargin/DeckPileBody/DeckPileCount
@onready var _discard_pile_count: Label = $EncounterRoot/BoardArea/DiscardPile/DiscardPileMargin/DiscardPileBody/DiscardPileCount
@onready var _hand_fan: HandFanView = $EncounterRoot/HandShell/HandFanView
@onready var _effect_overlay: EncounterEffectOverlayView = $EncounterEffectOverlayView

func _ready() -> void:
	_effect_overlay.set_anchor_provider(Callable(self, "_anchor_rect_for_feedback"))
	_prompt_view.end_turn_requested.connect(func() -> void: end_turn_requested.emit())
	_customer_view.focus_customer_requested.connect(func(customer_index: int) -> void:
		focus_customer_requested.emit(customer_index)
	)
	_customer_view.customer_target_requested.connect(func(customer_index: int) -> void:
		customer_item_requested.emit(customer_index)
	)
	_prep_view.prep_item_requested.connect(func(item_index: int) -> void:
		prep_item_requested.emit(item_index)
	)
	_oven_view.oven_item_requested.connect(func(slot_index: int) -> void:
		oven_item_requested.emit(slot_index)
	)
	_table_view.table_item_requested.connect(func(item_index: int) -> void:
		table_item_requested.emit(item_index)
	)
	_hand_fan.play_card_requested.connect(func(card_index: int) -> void:
		play_card_requested.emit(card_index)
	)

func configure_event_bus(event_bus: EventBus) -> void:
	_effect_overlay.configure(event_bus)

func render(session_service: SessionService, interaction_state: EncounterInteractionState) -> void:
	_prompt_view.render(interaction_state.pending_prompt)
	_hud_view.render(session_service)
	_customer_view.render(session_service, interaction_state)
	_prep_view.render(session_service, interaction_state)
	_oven_view.render(session_service, interaction_state)
	_table_view.render(session_service, interaction_state)
	_deck_pile_count.text = str(session_service.deck_state.draw_pile.size())
	_discard_pile_count.text = str(session_service.deck_state.discard_pile.size())
	_hand_fan.render(session_service, interaction_state)

func _anchor_rect_for_feedback(feedback: PastryFeedbackEvent) -> Rect2:
	if feedback == null:
		return Rect2()
	var card_control: Control = null
	match feedback.zone:
		&"prep":
			card_control = _prep_view.get_pastry_card_control(feedback.index)
		&"table":
			card_control = _table_view.get_pastry_card_control(feedback.index)
		&"oven":
			card_control = _oven_view.get_pastry_card_control(feedback.index)
		_:
			card_control = null
	if card_control == null:
		return Rect2()
	return Rect2(card_control.global_position - global_position, card_control.size)
