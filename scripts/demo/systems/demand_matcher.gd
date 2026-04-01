class_name DemandMatcher
extends RefCounted

func evaluate(food_state: DemoFoodState, demand_rules: Array[DemoDemandRule]) -> Dictionary:
	var default_result: Dictionary = {
		"success": false,
		"tier": &"fail",
		"score": 0,
		"tips": 0,
		"message": "This dish does not meet the request.",
		"stress_delta": 0,
	}
	if food_state == null or demand_rules.is_empty():
		return default_result
	var best_result: Dictionary = default_result
	var best_score: int = -9999
	for rule_value in demand_rules:
		var rule: DemoDemandRule = rule_value
		if rule == null:
			continue
		var candidate: Dictionary = _evaluate_single_rule(food_state, rule)
		var candidate_score: int = int(candidate.get("score", -9999))
		if candidate_score > best_score:
			best_score = candidate_score
			best_result = candidate
	return best_result

func _evaluate_single_rule(food_state: DemoFoodState, rule: DemoDemandRule) -> Dictionary:
	for forbidden_tag_value in rule.forbidden_tags:
		var forbidden_tag: String = forbidden_tag_value
		if food_state.has_tag(StringName(forbidden_tag)):
			return {
				"success": false,
				"tier": &"fail",
				"score": 0,
				"tips": 0,
				"message": "Forbidden tag present: %s." % String(forbidden_tag),
				"stress_delta": 0,
			}
	for required_tag_value in rule.required_tags:
		var required_tag: String = required_tag_value
		if not food_state.has_tag(StringName(required_tag)):
			return {
				"success": false,
				"tier": &"fail",
				"score": 0,
				"tips": 0,
				"message": "Missing required tag: %s." % String(required_tag),
				"stress_delta": 0,
			}
	if food_state.quality < rule.min_quality:
		return {
			"success": false,
			"tier": &"fail",
			"score": 0,
			"tips": 0,
			"message": "Dish quality is too low.",
			"stress_delta": 0,
		}
	var required_weight: int = int(rule.score_weights.get("required_weight", 2))
	var optional_weight: int = int(rule.score_weights.get("optional_weight", 1))
	var quality_weight: int = int(rule.score_weights.get("quality_weight", 1))
	var optional_matches: int = 0
	for optional_tag_value in rule.optional_tags:
		var optional_tag: String = optional_tag_value
		if food_state.has_tag(StringName(optional_tag)):
			optional_matches += 1
	var score: int = (
		rule.required_tags.size() * required_weight
		+ optional_matches * optional_weight
		+ food_state.quality * quality_weight
		+ food_state.score_bonus
	)
	var success_threshold: int = int(rule.score_weights.get("success_threshold", 2 + rule.required_tags.size()))
	var good_threshold: int = int(rule.score_weights.get("good_threshold", success_threshold + 2))
	var perfect_threshold: int = int(rule.score_weights.get("perfect_threshold", good_threshold + 2))
	if score < success_threshold:
		return {
			"success": false,
			"tier": &"fail",
			"score": score,
			"tips": 0,
			"message": "The customer wanted more from the dish.",
			"stress_delta": 0,
		}
	var tip_basic: int = int(rule.score_weights.get("tip_basic", 2))
	var tip_good: int = int(rule.score_weights.get("tip_good", 3))
	var tip_perfect: int = int(rule.score_weights.get("tip_perfect", 4))
	if score >= perfect_threshold:
		return {
			"success": true,
			"tier": &"perfect",
			"score": score,
			"tips": tip_perfect,
			"message": "Perfect match. The customer is delighted.",
			"stress_delta": 0,
		}
	if score >= good_threshold:
		return {
			"success": true,
			"tier": &"good",
			"score": score,
			"tips": tip_good,
			"message": "Great match. The customer leaves happy.",
			"stress_delta": 0,
		}
	return {
		"success": true,
		"tier": &"basic",
		"score": score,
		"tips": tip_basic,
		"message": "The request is satisfied.",
		"stress_delta": 0,
	}
