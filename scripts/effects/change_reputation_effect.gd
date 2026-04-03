class_name ChangeReputationEffect
extends BaseEffect

@export var amount: int = 0

func apply(context: EffectContext) -> void:
	if context.session_service == null:
		return
	context.session_service.apply_reputation_delta(amount)
