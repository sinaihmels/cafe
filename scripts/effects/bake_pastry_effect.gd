class_name BakePastryEffect
extends BaseEffect

func apply(context: EffectContext) -> void:
	if context.session_service != null:
		context.session_service.bake_active_pastry()
