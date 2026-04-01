class_name ConditionalDrawEffect
extends BaseEffect

@export var amount: int = 1
@export var prep_empty_bonus: int = 1

func apply(context: EffectContext) -> void:
	if context.deck_state == null or context.cafe_state == null:
		return
	var draw_amount: int = amount
	if context.cafe_state.prep_items.is_empty():
		draw_amount += prep_empty_bonus
	for _i: int in range(draw_amount):
		context.deck_state.draw_one()
