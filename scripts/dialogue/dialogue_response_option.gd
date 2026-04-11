class_name DialogueResponseOption
extends RefCounted

var response_id: StringName = &""
var text: String = ""
var next_node_id: StringName = &""
var disabled: bool = false

func duplicate_option() -> DialogueResponseOption:
	var copy: DialogueResponseOption = DialogueResponseOption.new()
	copy.response_id = response_id
	copy.text = text
	copy.next_node_id = next_node_id
	copy.disabled = disabled
	return copy
