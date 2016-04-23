tool

extends Node

export var run_all_suites = true
export var run_only_suite = ""
export var selected_suites = StringArray()

var suites = Array()
var completed = 0

func _ready():
	get_suites()
	sanitize_selected_suites()
	
	if will_run_all():
		for suite in suites:
			run_suite(suite)
	elif will_run_only_one_suite():
		run_suite(run_only_suite)
	elif will_run_selected_suites():
		for suite in selected_suites:
			run_suite(suite)
	else:
		print("ERROR: 0 test suites executed.")

func get_suites():
	for suite in get_children():
		suite.connect("suite_on_finish", self, "suite_on_finish")
		var name = suite.get_name()
		suites.push_back(name)

func suite_on_finish(suite):
	completed += 1
	if should_print_summary():
		print_summary()

func should_print_summary():
	return completed == suites.size()

func print_summary():
	var success = 0
	var fail = 0
	var asserts = 0
	var cases = 0
	var expectation = 0
	var fail_assert = 0
	var errors = 0
	var suite_count = suites.size()
	for name in suites:
		var suite = get_node(name)
		if suite.has_error():
			errors += 1
		success += suite.get_success_count()
		fail += suite.get_fail_count()
		asserts += suite.get_assertion_count()
		cases += suite.get_test_case_count()
		expectation += suite.get_expectation_count()
		fail_assert += suite.get_failed_assertion_count()
	
	print("\r")
	print("===================================")
	print("SUMMARY: ")
	if errors > 0:
		print(">>> ERROR: ", errors, " test suites.")
	print(suite_count, " test suites.")
	print(cases, " test cases.")
	print(success, " test cases succeded.")
	print(fail, " test cases failed.")
	print(asserts, " assertions performed.")
	print(fail_assert, " assertions failed.")
	print(expectation, " expectations finished.")
	print("===================================")

func sanitize_selected_suites():
	# Array of non-empty suite names
	var array = Array()
	
	# Check for empty
	for suite in selected_suites:
		if not suite.empty():
			array.push_back(suite)
	
	# Contains non-redundant suite names
	var array_2 = Array()
	
	# Check for duplicates
	for suite in array:
		if array_2.find(suite) < 0:
			array_2.push_back(suite)
	
	# Clear selected suites
	selected_suites.resize(0)
	for suite in array_2:
		selected_suites.push_back(suite)

func has_suite(name):
	var ok = true
	if suites.find(name) < 0:
		ok = false
		if not name.empty():
			print("ERROR: ", name, " does not exist.")
	return ok

func will_run_all():
	var ok = false
	if suites.size() > 0:
		ok = true
	return ok and run_all_suites

func will_run_selected_suites():
	var ok = false
	for suite in selected_suites:
		if has_suite(suite):
			ok = true
		else:
			ok = false
	return ok

func will_run_only_one_suite():
	var ok = false
	if has_suite(run_only_suite):
		ok = true
	return ok

func run_suite(name):
	var suite = get_node(name)
	suite.run()
