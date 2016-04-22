
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

func connect_on_finish(object, object_signal):
	object.connect(object_signal, self, "on_finish_expecting")

func on_finish_expecting(arg0=null, arg1=null, arg2=null, arg3=null, arg4=null, arg5=null, arg6=null, arg7=null, arg8=null, arg9=null):
	OS.delay_msec(100)
	yield()
	emit_signal("on_finish", self)
