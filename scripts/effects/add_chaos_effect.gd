class_name AddChaosEffect
extends BaseEffect

@export var amount: int = 1

func apply(context: EffectContext) -> void:
	context.player_state.chaos += amount
	if context.event_bus != null:
		context.event_bus.emit_effect_applied(self, context)
