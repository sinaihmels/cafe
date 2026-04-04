class_name SetPastryFlagEffect
extends BaseEffect

@export var flag_name: StringName = &""
@export var flag_value: bool = true

func apply(context: EffectContext) -> void:
	if context.session_service != null:
		context.session_service.set_selected_pastry_flag(context.targets, flag_name, flag_value)
