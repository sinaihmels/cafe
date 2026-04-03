class_name ModifyItemEffect
extends BaseEffect

@export var replacement_item_id: StringName = &""
@export var required_source_item_ids: PackedStringArray = []
@export var required_source_tags: PackedStringArray = []
@export var added_tags: PackedStringArray = []
@export var quality_delta: int = 0

func apply(context: EffectContext) -> void:
	if context.session_service == null:
		return
	context.session_service.modify_selected_prep_item(
		context.targets,
		replacement_item_id,
		required_source_item_ids,
		required_source_tags,
		added_tags,
		quality_delta
	)
