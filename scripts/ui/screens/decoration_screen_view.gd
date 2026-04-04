class_name DecorationScreenView
extends VBoxContainer

signal close_requested()
signal place_decoration_requested(slot_name: String, decoration_id: StringName)

@export var decoration_slot_scene: PackedScene
@export var choice_entry_scene: PackedScene

@onready var _back_button: Button = $BackToHubButton
@onready var _slots_container: VBoxContainer = $DecorationSlots

const SLOT_NAMES: Array[String] = ["wall", "counter", "floor", "shelf", "exterior"]

func _ready() -> void:
	_back_button.pressed.connect(func() -> void: close_requested.emit())

func render(session_service: SessionService) -> void:
	UiSceneUtils.clear_children(_slots_container)
	var profile: MetaProfileState = session_service.get_profile_state()
	for slot_name in SLOT_NAMES:
		var owned_options: Array[DecorationDef] = []
		for decoration_value in session_service.get_available_decorations():
			var decoration: DecorationDef = decoration_value
			if session_service.get_decoration_slot_name(decoration.slot) != slot_name:
				continue
			if not profile.owned_decoration_ids.has(decoration.decoration_id):
				continue
			owned_options.append(decoration)
		var slot_view: DecorationSlotView = _instantiate_slot_view()
		slot_view.choice_entry_scene = choice_entry_scene
		slot_view.configure(slot_name, String(profile.decoration_layout.get(slot_name, "")), owned_options)
		slot_view.clear_requested.connect(func(requested_slot: String) -> void:
			place_decoration_requested.emit(requested_slot, &"")
		)
		slot_view.decoration_requested.connect(func(requested_slot: String, decoration_id: StringName) -> void:
			place_decoration_requested.emit(requested_slot, decoration_id)
		)
		_slots_container.add_child(slot_view)

func _instantiate_slot_view() -> DecorationSlotView:
	var node: Node = UiSceneUtils.instantiate_required(decoration_slot_scene, "DecorationScreenView.decoration_slot_scene")
	var slot_view: DecorationSlotView = node as DecorationSlotView
	assert(slot_view != null, "DecorationScreenView.decoration_slot_scene must instantiate DecorationSlotView.")
	return slot_view
