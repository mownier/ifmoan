
extends Reference

signal task_on_finish(task)

var object = null
var method = null
var args = null

func _init(object, method, args=[]):
	self.object = object
	self.method = method
	self.args = args

func get_object():
	return object

func execute():
	if is_feasible():
		object.callv(method, args)
		emit_signal("task_on_finish", self)

func is_feasible():
	return (object != null and 
			method != null and 
			object.has_method(method) and 
			args != null)

func cleanup():
	object = null
	method = null
	args = null