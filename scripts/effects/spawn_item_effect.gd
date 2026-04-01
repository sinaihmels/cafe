class_name SpawnItemEffect
extends BaseEffect

@export var item_id: StringName

func apply(context: EffectContext) -> void:
	if context.session_service != null:
		context.session_service.spawn_item_in_prep(item_id)
