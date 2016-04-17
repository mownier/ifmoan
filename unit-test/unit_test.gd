tool

extends Node

export var run_all = true
export var run_only = ""
export var selected = []

func _ready():
	if run_all or (run_only.empty() and selected.empty()):
		for test in get_children():
			test.run()
	else:
		if not run_only.empty():
			run_test(run_only)
		else:
			for test_name in selected:
				run_test(test_name)

func run_test(name):
	var test = get_node(name)
	test.run()