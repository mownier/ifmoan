
extends Reference

signal on_finish(expectation)

var suite = null
var case = null
var name = null

func _init(suite, case, name):
	self.suite = suite
	self.case = case
	self.name = name

func get_name():
	return name

func get_suite():
	return suite

func get_case():
	return case
