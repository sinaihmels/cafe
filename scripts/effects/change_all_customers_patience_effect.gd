class_name ChangeAllCustomersPatienceEffect
extends BaseEffect

@export var amount: int = 0

func apply(context: EffectContext) -> void:
	if context.session_service != null:
		context.session_service.modify_all_customers_patience(amount)
