class_name AddPastryStatesEffect
extends BaseEffect

@export var states_to_add: PackedStringArray = []
@export var duration: int = -1
@export var quality_delta: int = 0

func apply(context: EffectContext) -> void:
	if context.session_service == null:
		return
	context.session_service.add_states_to_pastry(context.targets, states_to_add, duration, quality_delta)
