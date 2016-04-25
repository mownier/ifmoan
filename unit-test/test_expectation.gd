
extends Reference

signal on_finish(expectation)

var suite = null
var case = null
var name = null

func set_name(expectation_name):
	name = expectation_name

func set_suite(test_suite):
	suite = test_suite

func set_case(test_case):
	case = test_case

func get_name():
	return name

func get_suite():
	return suite

func get_case():
	return case

func wrap_up():
	emit_signal("on_finish", self)
