tool

extends Node

export var run_all_test_cases = true
export var run_only_test_case = ""
export var selected_test_cases = StringArray()

var test_cases = Array()
var current_test_case = ""
var fail = 0
var expectations = Dictionary()
var error = 0
var success = 0

func _ready():
	_get_test_cases()
	_sanitize_selected_test_cases()

func _get_test_cases():
	for method in get_method_list():
		var test_case = method["name"]
		if test_case.begins_with("test_"):
			test_cases.push_back(test_case)

func _run_test_case(test_case):
	setup()
	current_test_case = test_case
	call(test_case)
	teardown()

func _run_test_cases(tests):
	if tests.size() == 0:
		_raise_error("0 test cases executed")
	else:
		for test_case in tests:
			_run_test_case(test_case)

func _evaluate():
	if not has_expectations() and not _has_error():
		if _is_succeeded():
			print("[", get_name(), "] TEST SUCCESS")
		else:
			print("[", get_name(), "] TEST FAIL: ", fail)

func _sanitize_selected_test_cases():
	# Array of non-empty test cases
	var array = Array()
	
	# Check for empty
	for test_case in selected_test_cases:
		if not test_case.empty():
			array.push_back(test_case)
	
	# Contains non-redundant test cases
	var array_2 = Array()
	
	# Check for duplicates
	for test_case in array:
		if array_2.find(test_case) < 0:
			array_2.push_back(test_case)
	
	# Clear selected test cases
	selected_test_cases.resize(0)
	for test_case in array_2:
		selected_test_cases.push_back(test_case)

func _has_error():
	return error > 0

func _is_succeeded():
	return fail == 0

func _print_fail_message(message):
	fail += 1
	var fail_message = str("FAIL: ", current_test_case, " > ", message)
	_print_message(fail_message)

func _print_success_message(test_case):
	success += 1
	var success_message = str("OK: ", test_case)
	_print_message(success_message)

func _print_message(message):
	print("[", get_name(), "] ", message)

func _raise_error(message):
	error += 1
	_print_message(str("ERROR: ", message))

func _on_finish_expectation(expectation):
	expectations.erase(expectation.get_name())
	_evaluate()

func _has_test_case(test_case):
	var ok = true
	if test_cases.find(test_case) < 0:
		ok = false
		var message = ""
		if not test_case.empty():
			message = str(test_case, " does not exist")
		else:
			message = str("You provided an empty test case name.")
		_raise_error(message)
	return ok

func _will_run_only_one_test_case():
	var ok = false
	if _has_test_case(run_only_test_case):
		ok = true
	return ok

func _will_run_selected_test_cases():
	var ok = false
	for test_case in selected_test_cases:
		if _has_test_case(test_case):
			ok = true
		else:
			ok = false
	return ok

func setup():
	pass

func teardown():
	pass

func run():
	if run_all_test_cases:
		_run_test_cases(test_cases)
	elif _will_run_only_one_test_case():
		_run_test_cases([run_only_test_case])
	elif _will_run_selected_test_cases():
		_run_test_cases(selected_test_cases)
	_evaluate()

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

func assert_null(variable, message):
	if variable != null:
		_print_fail_message(message)

func assert_not_null(variable, message):
	if variable == null:
		_print_fail_message(message)

func assert_empty(variable, message):
	if not variable.empty():
		_print_fail_message(message)

func assert_not_empty(variable, message):
	if variable.empty():
		_print_fail_message(message)

func assert_equal(var1, var2, message):
	if var1 != var2:
		_print_fail_message(message)

func assert_not_equal(var1, var2, message):
	if var1 == var2:
		_print_fail_message(message)

func assert_equal_array(arr1, arr2, message):
	var ok = true
	if arr1.size() == arr2.size():
		for i in range(arr1.size()):
			var item1 = arr1[i]
			var item2 = arr2[i]
			if item1 != item2:
				ok = false
				break
	else:
		ok = false
	
	if not ok:
		_print_fail_message(message)

func assert_equal_dictionary(dict1, dict2, message):
	var ok = true
	if (dict1.size() == dict2.size() and
		dict1.keys().size() == dict2.keys().size()):
		for key in dict1:
			if not dict2.has(key):
				ok = false
				break
			else:
				var val1 = dict1[key]
				var val2 = dict2[key]
				if val1 != val2:
					ok = false
					break
	else:
		ok = false
	
	if not ok:
		_print_fail_message(message)