class_name ShopScreenView
extends VBoxContainer

signal offer_requested(offer_id: StringName)
signal continue_requested()

@export var choice_entry_scene: PackedScene

@onready var _list_container: VBoxContainer = $OfferList
@onready var _continue_button: Button = $ContinueShopButton

func _ready() -> void:
	_continue_button.pressed.connect(func() -> void: continue_requested.emit())

func render(session_service: SessionService) -> void:
	UiSceneUtils.clear_children(_list_container)
	for offer_value in session_service.get_pending_shop_offers():
		var offer: CardOfferDef = offer_value
		var entry: ChoiceEntryView = _instantiate_choice_entry()
		entry.configure(
			UiTextureLibrary.offer_texture(session_service.content_library, offer),
			offer.display_name,
			offer.description,
			"Cost %d" % offer.cost,
			"Buy"
		)
		var offer_id: StringName = offer.offer_id
		entry.primary_action_requested.connect(func() -> void:
			offer_requested.emit(offer_id)
			)
		_list_container.add_child(entry)

func _instantiate_choice_entry() -> ChoiceEntryView:
	var node: Node = UiSceneUtils.instantiate_required(choice_entry_scene, "ShopScreenView.choice_entry_scene")
	var entry: ChoiceEntryView = node as ChoiceEntryView
	assert(entry != null, "ShopScreenView.choice_entry_scene must instantiate ChoiceEntryView.")
	return entry
