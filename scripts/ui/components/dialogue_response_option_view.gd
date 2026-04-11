class_name DialogueResponseOptionView
extends Button

signal response_selected(response_index: int)

var _response_index: int = -1

func _ready() -> void:
	pressed.connect(_on_pressed)

func configure(response_index: int, option: DialogueResponseOption) -> void:
	_response_index = response_index
	text = option.text
	disabled = option.disabled

func _on_pressed() -> void:
	if _response_index >= 0:
		response_selected.emit(_response_index)
