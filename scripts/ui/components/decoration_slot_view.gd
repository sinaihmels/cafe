class_name DecorationSlotView
extends PanelContainer

signal clear_requested(slot_name: String)
signal decoration_requested(slot_name: String, decoration_id: StringName)

@export var choice_entry_scene: PackedScene

@onready var _title_label: Label = $Margin/Body/HeaderRow/TitleLabel
@onready var _current_label: Label = $Margin/Body/CurrentLabel
@onready var _clear_button: Button = $Margin/Body/HeaderRow/ClearButton
@onready var _options_container: VBoxContainer = $Margin/Body/OptionsContainer

var _slot_name: String = ""
var _current_value: String = ""
var _options: Array[DecorationDef] = []

func _ready() -> void:
	_clear_button.pressed.connect(_on_clear_pressed)
	_apply_configuration()

func configure(slot_name: String, current_value: String, options: Array[DecorationDef]) -> void:
	_slot_name = slot_name
	_current_value = current_value
	_options = options
	if is_node_ready():
		_apply_configuration()

func _apply_configuration() -> void:
	_title_label.text = _slot_name.capitalize()
	_current_label.text = "Current: %s" % (_current_value if _current_value != "" else "Empty")
	UiSceneUtils.clear_children(_options_container)
	for decoration in _options:
		var entry: ChoiceEntryView = _instantiate_choice_entry()
		entry.configure(
			UiTextureLibrary.decoration_texture(decoration),
			decoration.display_name,
			decoration.description,
			"Owned",
			"Place"
		)
		var decoration_id: StringName = decoration.decoration_id
		entry.primary_action_requested.connect(func() -> void:
			decoration_requested.emit(_slot_name, decoration_id)
		)
		_options_container.add_child(entry)

func _on_clear_pressed() -> void:
	clear_requested.emit(_slot_name)

func _instantiate_choice_entry() -> ChoiceEntryView:
	var node: Node = UiSceneUtils.instantiate_required(choice_entry_scene, "DecorationSlotView.choice_entry_scene")
	var entry: ChoiceEntryView = node as ChoiceEntryView
	assert(entry != null, "DecorationSlotView.choice_entry_scene must instantiate ChoiceEntryView.")
	return entry
