class_name DialoguePresentationState
extends RefCounted

var revision: int = 0
var visible: bool = false
var blocking_input: bool = false
var modal: bool = false
var customer_runtime_id: int = 0
var customer_index: int = -1
var cue: StringName = &""
var speaker_name: String = ""
var speaker_kind: StringName = &"customer"
var text: String = ""
var portrait: Texture2D
var allow_continue: bool = false
var auto_advance_seconds: float = 0.0
var responses: Array[DialogueResponseOption] = []

func has_responses() -> bool:
	return not responses.is_empty()

func duplicate_state() -> DialoguePresentationState:
	var copy: DialoguePresentationState = DialoguePresentationState.new()
	copy.revision = revision
	copy.visible = visible
	copy.blocking_input = blocking_input
	copy.modal = modal
	copy.customer_runtime_id = customer_runtime_id
	copy.customer_index = customer_index
	copy.cue = cue
	copy.speaker_name = speaker_name
	copy.speaker_kind = speaker_kind
	copy.text = text
	copy.portrait = portrait
	copy.allow_continue = allow_continue
	copy.auto_advance_seconds = auto_advance_seconds
	for response in responses:
		copy.responses.append(response.duplicate_option())
	return copy
