
extends Node

var test_methods = StringArray()
var current_method = ""
var fail = 0
var expectations = Dictionary()

func run():
	_get_test_methods()
	_run_test_methods()
	_evaluate_tests()

func _get_test_methods():
	for method in get_method_list():
		var name = method["name"]
		if name.begins_with("test_") and should_execute_test(name):
			test_methods.push_back(name)

func _run_test_methods():
	for method in test_methods:
		current_method = method
		call(method)

func _evaluate_tests():
	if not has_expectations():
		if _is_succeeded():
			print("[", get_name(), "] TEST SUCCESS")
		else:
			print("[", get_name(), "] TEST FAIL: ", fail)

func _is_succeeded():
	return fail == 0

func _print_fail_message(message):
	fail += 1
	print("FAIL: ", current_method, " > ", message)

func _on_finish_expectation(expectation):
	expectations.erase(expectation.get_name())
	_evaluate_tests()

func should_execute_test(method):
	return true

func add_expectation(expectation):
	expectation.connect("on_finish", self, "_on_finish_expectation")
	var name = expectation.get_name()
	expectations[name] = expectation

func has_expectations():
	return expectations.size() > 0

func assert_true(condition, message):
	if not condition:
		_print_fail_message(message)

func assert_false(condition, message):
	if condition:
		_print_fail_message(message)