
extends Reference

signal pool_on_idle(pool)
signal pool_on_fulfill(pool, task)
signal pool_on_execute(pool, task)

var thread_pool_worker = preload("thread_pool_worker.gd")

var mutex = Mutex.new()
var thread = Thread.new()
var terminated = true
var waiting_workers = Array() # Array of waiting workers
var working_workers = Array() # Array of busy workers
var tasks = Array() # Array of tasks

func _init(worker_count=10):
	_create_workers(worker_count)

func _create_workers(worker_count):
	for i in range(worker_count):
		var worker_thread = Thread.new()
		var worker = thread_pool_worker.new(worker_thread)
		worker.connect("worker_on_finish", self, "_on_finish_working")
		waiting_workers.push_back(worker)

func _on_finish_working(worker):
	mutex.lock()
	
	var found = false
	for w in working_workers:
		if w == worker:
			found = true
			break
	if found:
		waiting_workers.push_back(worker)
		working_workers.erase(worker)
	
	mutex.unlock()
	
	emit_signal("pool_on_fulfill", self, worker.get_task())
	
	if is_idle():
		emit_signal("pool_on_idle", self)

func _start_pool(data):
	while not is_terminated():
		if has_tasks():
			if has_waiting_workers():
				mutex.lock()
				
				var task = tasks[0]
				tasks.pop_front()
				
				var worker = waiting_workers[0]
				waiting_workers.pop_front()
				working_workers.push_back(worker)
				
				mutex.unlock()
				
				emit_signal("pool_on_execute", self, task)
				worker.execute(task)
		OS.delay_msec(100)
	
	mutex.lock()
	thread.wait_to_finish()
	mutex.unlock()

func has_waiting_workers():
	mutex.lock()
	var ok = waiting_workers.size() > 0
	mutex.unlock()
	return ok

func has_working_workers():
	mutex.lock()
	var ok = working_workers.size() > 0
	mutex.unlock()
	return ok

func has_tasks():
	mutex.lock()
	var ok = tasks.size() > 0
	mutex.unlock()
	return ok

func add_task(task):
	mutex.lock()
	tasks.push_back(task)
	mutex.unlock()

func start():
	if is_terminated():
		terminated = false
		thread.start(self, "_start_pool")

func terminate():
	mutex.lock()
	terminated = true
	mutex.unlock()

func is_idle():
	mutex.lock()
	var ok = not has_tasks() and not has_working_workers()
	mutex.unlock()
	return ok

func is_terminated():
	return terminated
