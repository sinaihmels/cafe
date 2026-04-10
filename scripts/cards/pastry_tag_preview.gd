class_name PastryTagPreview
extends RefCounted

var tag_id: StringName = &""
var is_conditional: bool = false
var condition_text: String = ""

func _init(tag_id_value: StringName = &"", conditional: bool = false, condition_text_value: String = "") -> void:
	tag_id = tag_id_value
	is_conditional = conditional
	condition_text = condition_text_value

func duplicate_preview() -> PastryTagPreview:
	return PastryTagPreview.new(tag_id, is_conditional, condition_text)
