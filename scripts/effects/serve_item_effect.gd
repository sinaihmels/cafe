class_name ServeItemEffect
extends BaseEffect

func apply(context: EffectContext) -> void:
	if context.session_service == null:
		return
	context.session_service.serve_targets(context.targets)
