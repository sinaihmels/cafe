class_name EventBus
extends Node

signal card_played(card: CardInstance)
signal item_baked(item_id: StringName)
signal customer_served(customer_id: StringName)
signal turn_started(turn_number: int)
signal turn_ended(turn_number: int)
signal effect_applied(effect: BaseEffect, context: EffectContext)
signal pastry_feedback_requested(feedback: PastryFeedbackEvent)
signal energy_changed(new_energy: int, delta: int)
signal dialogue_requested(request: DialogueRequest)

func emit_card_played(card: CardInstance) -> void:
	card_played.emit(card)

func emit_item_baked(item_id: StringName) -> void:
	item_baked.emit(item_id)

func emit_customer_served(customer_id: StringName) -> void:
	customer_served.emit(customer_id)

func emit_turn_started(turn_number: int) -> void:
	turn_started.emit(turn_number)

func emit_turn_ended(turn_number: int) -> void:
	turn_ended.emit(turn_number)

func emit_effect_applied(effect: BaseEffect, context: EffectContext) -> void:
	effect_applied.emit(effect, context)

func emit_pastry_feedback_requested(feedback: PastryFeedbackEvent) -> void:
	pastry_feedback_requested.emit(feedback)

func emit_energy_changed(new_energy: int, delta: int) -> void:
	energy_changed.emit(new_energy, delta)

func emit_dialogue_requested(request: DialogueRequest) -> void:
	dialogue_requested.emit(request)
