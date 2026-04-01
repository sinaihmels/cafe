class_name RandomBasicIngredientEffect
extends BaseEffect

@export var item_ids: PackedStringArray = PackedStringArray(["flour", "butter", "sugar"])

func apply(context: EffectContext) -> void:
	if context.session_service == null or item_ids.is_empty():
		return
	var index: int = randi() % item_ids.size()
	context.session_service.spawn_item_in_prep(StringName(item_ids[index]))
