class_name ChangeStressEffect
extends BaseEffect

@export var amount: int = 0

func apply(context: EffectContext) -> void:
	if context.player_state == null:
		return
	if amount >= 0:
		context.player_state.heal_stress(amount)
	else:
		context.player_state.lose_stress(-amount)
