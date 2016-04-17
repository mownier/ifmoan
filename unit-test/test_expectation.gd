
extends Reference

signal on_finish(expectation)

var test_suite
var test_method
var expectation_name

func _init(suite, method, name):
	test_suite = suite
	test_method = method
	expectation_name = name

func get_name():
	return expectation_name