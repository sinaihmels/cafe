@tool
class_name EncounterPromptView
extends PanelContainer

@onready var _prompt_label: Label = $PromptMargin/PromptLabel

func render(prompt_text: String) -> void:
	var cleaned_prompt: String = prompt_text.strip_edges()
	visible = cleaned_prompt != ""
	_prompt_label.text = cleaned_prompt
