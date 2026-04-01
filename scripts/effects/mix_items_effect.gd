class_name MixItemsEffect
extends BaseEffect

func apply(context: EffectContext) -> void:
	if context.session_service != null:
		context.session_service.mix_selected_prep_items(context.targets)
