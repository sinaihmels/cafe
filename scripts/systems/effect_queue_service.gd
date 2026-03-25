class_name EffectQueueService
extends Node

signal resolution_started()
signal resolution_finished()

var _queue: Array[Dictionary] = []
var _is_processing: bool = false
var _event_bus: EventBus

func configure(event_bus: EventBus) -> void:
	_event_bus = event_bus

func enqueue(effect: BaseEffect, context: EffectContext) -> void:
	_queue.append({
		"effect": effect,
		"context": context.duplicate_for_effect(),
	})

func enqueue_all(effects: Array[BaseEffect], context: EffectContext) -> void:
	for effect in effects:
		enqueue(effect, context)

func has_pending() -> bool:
	return not _queue.is_empty() or _is_processing

func resolve_all() -> void:
	if _is_processing:
		return
	_is_processing = true
	resolution_started.emit()
	while not _queue.is_empty():
		var entry: Dictionary = _queue.pop_front()
		var effect: BaseEffect = entry.get("effect")
		var context: EffectContext = entry.get("context")
		if effect == null or context == null:
			continue
		effect.apply(context)
		if _event_bus != null:
			_event_bus.emit_effect_applied(effect, context)
	_is_processing = false
	resolution_finished.emit()
