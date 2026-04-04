class_name AddPastryTagsEffect
extends BaseEffect

@export var tags_to_add: PackedStringArray = []
@export var required_pastry_tags: PackedStringArray = []
@export var required_pastry_states: PackedStringArray = []
@export var forbidden_pastry_states: PackedStringArray = []

func apply(context: EffectContext) -> void:
	if context.session_service == null:
		return
	context.session_service.add_tags_to_pastry(
		context.targets,
		tags_to_add,
		required_pastry_tags,
		required_pastry_states,
		forbidden_pastry_states
	)
