class_name BossIntroScreenView
extends VBoxContainer

signal start_boss_requested()

@onready var _boss_card: HeroCardView = $BossCard
@onready var _boss_text_label: Label = $BossTextLabel
@onready var _start_button: Button = $ChooseBossDoughButton

func _ready() -> void:
	_start_button.pressed.connect(func() -> void: start_boss_requested.emit())

func render(session_service: SessionService) -> void:
	var boss: CustomerDef = session_service.content_library.get_customer(&"critic_boss")
	_boss_card.configure(UiTextureLibrary.customer_texture(boss), boss.display_name if boss != null else "Boss")
	_boss_text_label.text = "The boss wants something sweet and decorated. Choose the dough for the final day, then prep, bake, and serve it before patience runs out."
