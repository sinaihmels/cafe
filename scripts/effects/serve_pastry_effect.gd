class_name ServePastryEffect
extends BaseEffect

func apply(context: EffectContext) -> void:
	if context.session_service != null:
		context.session_service.serve_targets(context.targets)
