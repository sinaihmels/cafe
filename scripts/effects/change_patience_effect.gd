class_name ChangePatienceEffect
extends BaseEffect

@export var amount: int = 0

func apply(context: EffectContext) -> void:
	if context.session_service == null:
		return
	context.session_service.modify_target_customer_patience(context.targets, amount)
