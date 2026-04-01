class_name DecorateItemEffect
extends BaseEffect

func apply(context: EffectContext) -> void:
	if context.session_service != null:
		context.session_service.decorate_selected_table_item(context.targets)
