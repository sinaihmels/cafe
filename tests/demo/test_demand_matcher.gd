extends SceneTree

func _init() -> void:
	var matcher: DemandMatcher = DemandMatcher.new()
	var rule: DemoDemandRule = DemoDemandRule.new()
	rule.required_tags = PackedStringArray(["sweet", "baked"])
	rule.optional_tags = PackedStringArray(["chocolate"])
	rule.min_quality = 1
	rule.score_weights = {
		"required_weight": 2,
		"optional_weight": 1,
		"quality_weight": 1,
		"success_threshold": 4,
		"good_threshold": 6,
		"perfect_threshold": 8,
	}
	var food: DemoFoodState = DemoFoodState.new()
	var fail_result: Dictionary = matcher.evaluate(food, [rule])
	assert(not bool(fail_result.get("success", false)), "Expected failure for missing required tags.")
	food.add_tag(&"sweet")
	food.add_tag(&"baked")
	food.add_tag(&"chocolate")
	food.quality = 2
	var success_result: Dictionary = matcher.evaluate(food, [rule])
	assert(bool(success_result.get("success", false)), "Expected success for valid dish.")
	assert(int(success_result.get("score", 0)) >= 7, "Expected scoring to include required, optional, and quality.")
	quit()
