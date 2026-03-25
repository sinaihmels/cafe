class_name DrawCardsEffect
extends BaseEffect

@export var amount: int = 1

func apply(context: EffectContext) -> void:
	for _i in amount:
		context.deck_state.draw_one()
	if context.event_bus != null:
		context.event_bus.emit_effect_applied(self, context)
