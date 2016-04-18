tool

extends Node

export var run_all_suites = true
export var run_only_suite = ""
export var selected_suites = StringArray()

var suites = Array()

func _ready():
	get_suites()
	sanitize_selected_suites()
	
	if run_all_suites:
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
		var name = suite.get_name()
		suites.push_back(name)

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
