class_name DrawCardsEffect
extends BaseEffect

@export var amount: int = 1

func apply(context: EffectContext) -> void:
	for _i: int in range(amount):
		context.deck_state.draw_one()
