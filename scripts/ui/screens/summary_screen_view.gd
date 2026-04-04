class_name SummaryScreenView
extends VBoxContainer

signal return_to_hub_requested()

@onready var _summary_label: Label = $SummaryLabel
@onready var _return_button: Button = $ReturnToHubButton

func _ready() -> void:
	_return_button.pressed.connect(func() -> void: return_to_hub_requested.emit())

func render(session_service: SessionService) -> void:
	_summary_label.text = session_service.run_state.summary_message
