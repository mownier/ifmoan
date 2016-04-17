
extends Reference

signal firebase_on_success(response)
signal firebase_on_error(response)
signal firebase_on_receive_stream(id, event, data)
signal firebase_on_finish_listening()

const DEFAULT_HEADER = ["User-Agent:Godot Engine 2.0", "Accept:*/*"]
const EVENT_SOURCE_HEADER = ["User-Agent:Godot Engine 2.0", "Accept:text/event-stream"]

var http_url = preload("res://ifmoan/http-request/http_url.gd")
var http_request = preload("res://ifmoan/http-request/http_request.gd")
var event_source = preload("res://ifmoan/event-source/event_source.gd")
var thread_pool_task = preload("res://ifmoan/thread-pool/thread_pool_task.gd")

var url
var host
var pool

func _init(app_url):
	url = http_url.new(app_url)
	var segments = url.parse_segments()
	host = segments["host"]

func get(path, query=""):
	var request_path = str(path, ".json/", query)
	return _request(HTTPClient.METHOD_GET, request_path, DEFAULT_HEADER)

func post(path, body=""):
	var request_path = str(path, ".json")
	return _request(HTTPClient.METHOD_POST, request_path, DEFAULT_HEADER, body)

func put(path, body=""):
	var request_path = str(path, ".json")
	return _request(HTTPClient.METHOD_PUT, request_path, DEFAULT_HEADER, body)

func delete(path, query=""):
	var request_path = str(path, ".json/", query)
	return _request(HTTPClient.METHOD_DELETE, request_path, DEFAULT_HEADER)

func patch(path, body=""):
	var request_path = str(path, ".json")
	var request_header = DEFAULT_HEADER
	request_header.append("X-HTTP-Method-Override:PATCH")
	return _request(HTTPClient.METHOD_PUT, request_path, request_header, body)

func listen(path):
	var source = _create_source(path)
	var task = thread_pool_task.new(source, "start")
	pool.add_task(task)
	return source

func set_thread_pool(thread_pool):
	pool = thread_pool

func _request(method, path, header=StringArray(), body=""):
	var request = _create_request()
	var args = [method, path, body, header]
	var task = thread_pool_task.new(request, "resume", args)
	pool.add_task(task)
	return request

func _create_request():
	var request = http_request.new(host)
	request.enable_ssl(true)
	request.connect("request_completed", self, "_on_request_completed")
	request.connect("completed_with_error", self, "_on_request_error")
	return request

func _create_source(path):
	var source_header = EVENT_SOURCE_HEADER
	var source_path = str(path, ".json")
	var source = event_source.new(host, source_path, source_header, true)
	source.connect("on_handle_event", self, "_on_handle_event")
	source.connect("on_message", self, "_on_message")
	source.connect("on_open", self, "_on_open")
	source.connect("on_error", self, "_on_error")
	source.connect("on_close", self, "_on_close")
	return source

func _on_request_completed(request, response):
	emit_signal("firebase_on_success", response)

func _on_request_error(request, response):
	emit_signal("firebase_on_error", response)

func _on_handle_event(source, id, event, data):
	emit_signal("firebase_on_receive_stream", id, event, data)

func _on_message(source, id, data):
	emit_signal("firebase_on_receive_stream", id, "message", data)

func _on_open(source):
	print("firebase event source state: open")

func _on_error(source, error):
	print("firebase event source error: ", error)

func _on_close(source):
	emit_signal("firebase_on_finish_listening")