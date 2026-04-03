class_name ChangeTipsEffect
extends BaseEffect

@export var amount: int = 0

func apply(context: EffectContext) -> void:
	if context.player_state == null:
		return
	context.player_state.gain_tips(amount)
