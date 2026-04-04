class_name ChangePastryQualityEffect
extends BaseEffect

@export var amount: int = 0

func apply(context: EffectContext) -> void:
	if context.session_service != null:
		context.session_service.change_selected_pastry_quality(context.targets, amount)
