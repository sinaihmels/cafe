class_name DialogueRequest
extends RefCounted

var customer_runtime_id: int = 0
var customer_id: StringName = &""
var cue: StringName = &""
var card_id: StringName = &""
var leave_reason: StringName = &""
var dialogue_path: String = ""
var modal: bool = false
var allow_choices: bool = false

func duplicate_request() -> DialogueRequest:
	var copy: DialogueRequest = DialogueRequest.new()
	copy.customer_runtime_id = customer_runtime_id
	copy.customer_id = customer_id
	copy.cue = cue
	copy.card_id = card_id
	copy.leave_reason = leave_reason
	copy.dialogue_path = dialogue_path
	copy.modal = modal
	copy.allow_choices = allow_choices
	return copy
