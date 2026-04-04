class_name ConditionalPastryEffect
extends BaseEffect

@export var required_pastry_tags: PackedStringArray = []
@export var required_pastry_states: PackedStringArray = []
@export var forbidden_pastry_states: PackedStringArray = []
@export var success_effects: Array[BaseEffect] = []

func apply(context: EffectContext) -> void:
	if context.session_service == null:
		return
	if context.session_service.selected_pastry_meets_conditions(
		context.targets,
		required_pastry_tags,
		required_pastry_states,
		forbidden_pastry_states
	):
		for effect in success_effects:
			if effect != null:
				effect.apply(context)
