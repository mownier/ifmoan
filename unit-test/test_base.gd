tool

extends Node

signal suite_on_finish(suite)

const TEST_SUCCESS = 0
const TEST_EXPECTING = 1
const TEST_FAIL = 2

export var run_all_test_cases = true
export var run_only_test_case = ""
export var selected_test_cases = StringArray()

var expectations = Dictionary()
var test_cases = Array()
var current_test_case = ""
var error = 0
var success = 0
var fail = 0
var expecting = 0
var assertions = 0
var assert_fail = 0

var info = {}

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
	set_current_test_case(test_case)
	call(test_case)
	teardown()

func _run_test_cases(tests):
	if tests.size() == 0:
		_raise_error("0 test cases executed")
	else:
		for test_case in tests:
			info[test_case] = TEST_SUCCESS
			_run_test_case(test_case)
			if info[test_case] == TEST_SUCCESS:
				_on_success(test_case)
			elif info[test_case] == TEST_EXPECTING:
				_on_expecting(test_case)

func _evaluate():
	if not _has_expectations():
		if not has_error():
			if _is_succeeded():
				_print_message("TEST SUCCESS")
			else:
				_print_message(str("TEST FAIL: ", fail))
		emit_signal("suite_on_finish", self)
		suite_on_stop()

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

func _is_succeeded():
	return fail == 0

func _print_expecting_message(test_case):
	var message = str("EXPECTING: ", test_case)
	_print_message(message)

func _print_fail_message(test_case, message):
	var fail_message = str("FAIL: ", test_case, " > ", message)
	_print_message(fail_message)

func _print_success_message(test_case):
	var message = str("OK: ", test_case)
	_print_message(message)

func _print_message(message):
	print("[", get_name(), "] ", message)

func _raise_error(message):
	error += 1
	_print_message(str("ERROR: ", message))

func _on_finish_expectation(expectation):
	expectations.erase(expectation.get_name())
	if info[expectation.get_case()] == TEST_EXPECTING:
		info[expectation.get_case()] = TEST_SUCCESS
		_on_success(expectation.get_case())
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

func _on_assert():
	assertions += 1

func _on_assert_fail(message, case=""):
	assert_fail += 1
	_on_fail(message, case)

func _on_success(test_case):
	success += 1
	_print_success_message(test_case)

func _on_expecting(test_case):
	expecting += 1
	_print_expecting_message(test_case)

func _on_fail(message, case=""):
	var test_case = case
	if test_case.empty():
		test_case = current_test_case
	if info[test_case] != TEST_FAIL:
		fail += 1
	info[test_case] = TEST_FAIL
	_print_fail_message(test_case, message)

func _has_expectations():
	return expectations.size() > 0

func has_expectation(name):
	return expectations.has(name)

func get_expectation(name):
	if has_expectation(name):
		return expectations[name]
	else:
		return null

func has_error():
	return error > 0
	
func get_success_count():
	return success

func get_fail_count():
	return fail

func get_assertion_count():
	return assertions

func get_failed_assertion_count():
	return assert_fail

func get_test_case_count():
	return test_cases.size()

func get_expectation_count():
	return expecting

func set_current_test_case(case):
	current_test_case = case

func setup():
	pass

func teardown():
	pass

func run():
	suite_on_start()
	if run_all_test_cases:
		_run_test_cases(test_cases)
	elif _will_run_only_one_test_case():
		_run_test_cases([run_only_test_case])
	elif _will_run_selected_test_cases():
		_run_test_cases(selected_test_cases)
	_evaluate()

func suite_on_start():
	pass

func suite_on_stop():
	pass

func add_expectation(expectation):
	info[current_test_case] = TEST_EXPECTING
	expectation.set_suite(self)
	expectation.set_case(current_test_case)
	expectation.connect("on_finish", self, "_on_finish_expectation")
	var name = expectation.get_name()
	expectations[name] = expectation

func fail(message, case=""):
	_on_fail(message, case)

func assert_true(condition, message, case=""):
	_on_assert()
	if not condition:
		_on_assert_fail(message, case)

func assert_false(condition, message, case=""):
	_on_assert()
	if condition:
		_on_assert_fail(message, case)

func assert_null(variable, message, case=""):
	_on_assert()
	if variable != null:
		_on_assert_fail(message, case)

func assert_not_null(variable, message, case=""):
	_on_assert()
	if variable == null:
		_on_assert_fail(message, case)

func assert_empty(variable, message, case=""):
	_on_assert()
	if not variable.empty():
		_on_assert_fail(message, case)

func assert_not_empty(variable, message, case=""):
	_on_assert()
	if variable.empty():
		_on_assert_fail(message, case)

func assert_equal(var1, var2, message, case=""):
	_on_assert()
	if var1 != var2:
		_on_assert_fail(message, case)

func assert_not_equal(var1, var2, message, case=""):
	_on_assert()
	if var1 == var2:
		_on_assert_fail(message, case)

func assert_equal_array(arr1, arr2, message, case=""):
	_on_assert()
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
		_on_assert_fail(message, case)

func assert_equal_dictionary(dict1, dict2, message, case=""):
	_on_assert()
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
		_on_assert_fail(message, case)
