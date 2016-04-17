
extends Reference

signal task_on_finish(task)

var object
var method
var args

func _init(object, method, args=[]):
	self.object = object
	self.method = method
	self.args = args

func get_object():
	return object

func execute():
	if (object != null and
		not method.empty() and
		object.has_method(method) and
		args != null):
		object.callv(method, args)
		emit_signal("task_on_finish", self)

func cleanup():
	object = null
	method = null
	args = null