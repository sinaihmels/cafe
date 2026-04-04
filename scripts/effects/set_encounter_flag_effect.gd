class_name SetEncounterFlagEffect
extends BaseEffect

@export var flag_name: StringName = &""
@export var amount: int = 1

func apply(context: EffectContext) -> void:
	if context.session_service != null:
		context.session_service.set_encounter_flag(flag_name, amount)
