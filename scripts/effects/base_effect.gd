class_name BaseEffect
extends Resource

@export var effect_id: StringName

func apply(_context: EffectContext) -> void:
	push_warning("%s has no apply() implementation." % [get_class()])
