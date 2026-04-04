class_name EncounterPromptView
extends PanelContainer

signal end_turn_requested()

@onready var _prompt_label: Label = $CenterMargin/CenterBody/PromptPanel/PromptMargin/PromptBody/PromptLabel
@onready var _end_turn_button: Button = $CenterMargin/CenterBody/CenterHeader/EndTurnButton

func _ready() -> void:
	_end_turn_button.pressed.connect(func() -> void: end_turn_requested.emit())

func render(prompt_text: String) -> void:
	_prompt_label.text = prompt_text if prompt_text != "" else "Choose a card below, then click the required spaces on the board."
