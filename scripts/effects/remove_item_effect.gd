class_name RemoveItemEffect
extends BaseEffect

func apply(context: EffectContext) -> void:
	if context.session_service != null:
		context.session_service.remove_selected_item(context.targets)
