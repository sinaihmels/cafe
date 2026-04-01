class_name BakeItemEffect
extends BaseEffect

@export var instant: bool = false
@export_range(0.0, 1.0, 0.01) var burn_chance: float = 0.0

func apply(context: EffectContext) -> void:
	if context.session_service == null:
		return
	if instant:
		context.session_service.flash_bake_selected_item(context.targets, burn_chance)
	else:
		context.session_service.bake_selected_prep_item(context.targets)
