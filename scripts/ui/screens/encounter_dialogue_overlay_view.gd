class_name EncounterDialogueOverlayView
extends Control

signal continue_requested()
signal response_requested(response_index: int)

@export var response_option_scene: PackedScene

@onready var _modal_backdrop: ColorRect = $ModalBackdrop
@onready var _modal_panel: PanelContainer = $ModalBackdrop/ModalPanel
@onready var _portrait: TextureRect = $ModalBackdrop/ModalPanel/ModalMargin/Content/TopRow/PortraitShell/Portrait
@onready var _speaker_label: Label = $ModalBackdrop/ModalPanel/ModalMargin/Content/TopRow/SpeakerColumn/SpeakerLabel
@onready var _text_label: Label = $ModalBackdrop/ModalPanel/ModalMargin/Content/TextLabel
@onready var _responses_column: VBoxContainer = $ModalBackdrop/ModalPanel/ModalMargin/Content/ResponsesColumn
@onready var _continue_button: Button = $ModalBackdrop/ModalPanel/ModalMargin/Content/ContinueButton
@onready var _bubble_panel: PanelContainer = $BubblePanel
@onready var _bubble_name_label: Label = $BubblePanel/BubbleMargin/BubbleColumn/BubbleNameLabel
@onready var _bubble_text_label: Label = $BubblePanel/BubbleMargin/BubbleColumn/BubbleTextLabel

var _anchor_provider: Callable

func _ready() -> void:
	_continue_button.pressed.connect(func() -> void:
		continue_requested.emit()
	)

func set_anchor_provider(anchor_provider: Callable) -> void:
	_anchor_provider = anchor_provider

func render(state: DialoguePresentationState) -> void:
	var is_visible: bool = state != null and state.visible
	visible = is_visible
	if not is_visible:
		return
	mouse_filter = Control.MOUSE_FILTER_STOP if state.modal else Control.MOUSE_FILTER_IGNORE
	_modal_backdrop.visible = state.modal
	_bubble_panel.visible = not state.modal
	if state.modal:
		_render_modal(state)
	else:
		_render_bubble(state)

func _render_modal(state: DialoguePresentationState) -> void:
	_portrait.visible = state.portrait != null
	_portrait.texture = state.portrait
	_speaker_label.text = state.speaker_name
	_text_label.text = state.text
	UiSceneUtils.clear_children(_responses_column)
	for response_index in range(state.responses.size()):
		var option: DialogueResponseOptionView = _instantiate_response_option()
		option.configure(response_index, state.responses[response_index])
		option.response_selected.connect(func(selected_index: int) -> void:
			response_requested.emit(selected_index)
		)
		_responses_column.add_child(option)
	_responses_column.visible = not state.responses.is_empty()
	_continue_button.visible = state.allow_continue and state.responses.is_empty()

func _render_bubble(state: DialoguePresentationState) -> void:
	_bubble_name_label.text = state.speaker_name
	_bubble_text_label.text = state.text
	if not _anchor_provider.is_valid():
		return
	var anchor_variant: Variant = _anchor_provider.call(state.customer_index)
	if not (anchor_variant is Rect2):
		return
	var anchor_rect: Rect2 = anchor_variant
	if anchor_rect.size == Vector2.ZERO:
		return
	var bubble_size: Vector2 = _bubble_panel.get_combined_minimum_size()
	_bubble_panel.position = Vector2(
		anchor_rect.position.x + (anchor_rect.size.x - bubble_size.x) * 0.5,
		maxf(0.0, anchor_rect.position.y - bubble_size.y - 18.0)
	)

func _instantiate_response_option() -> DialogueResponseOptionView:
	var node: Node = UiSceneUtils.instantiate_required(response_option_scene, "EncounterDialogueOverlayView.response_option_scene")
	var option: DialogueResponseOptionView = node as DialogueResponseOptionView
	assert(option != null, "EncounterDialogueOverlayView.response_option_scene must instantiate DialogueResponseOptionView.")
	return option
