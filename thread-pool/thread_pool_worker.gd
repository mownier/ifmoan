
extends Reference

signal worker_on_finish(worker)

var done = true
var thread = null
var task = null

func _init(worker_thread):
	thread = worker_thread

func is_done():
	return done

func execute(what):
	if thread.is_active():
		thread.wait_to_finish()
	task = what
	done = false
	task.connect("task_on_finish", self, "_on_task_finish")
	thread.start(self, "_start", task)

func get_task():
	return task

func _on_task_finish(task):
	done = true
	emit_signal("worker_on_finish", self)
	if task != null:
		task.cleanup()
	task = null
	thread.wait_to_finish()

func _start(task):
	if task != null and task.is_feasible():
		task.execute()
	else:
		_on_task_finish(task)