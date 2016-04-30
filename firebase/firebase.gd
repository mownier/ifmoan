
extends Reference

signal firebase_on_success(firebase, request, info)
signal firebase_on_error(firebase, object, error)
signal firebase_on_stream(firebase, source, event, data)
signal firebase_on_stop(firebase, source)

var request_header = ["Accept: */*"]

var HTTPUrl = preload("../http-request/http_url.gd")
var Request = preload("../http-request/http_request.gd")
var EventSource = preload("../event-source/event_source.gd")
var Task = preload("../thread-pool/thread_pool_task.gd")

var pending = [] # Pending operation

var url
var host
var pool
var auth

func _init(app_url):
	self.url = HTTPUrl.new(app_url)
	self.host = url.get_host()
	self.request_header.append(_get_user_agent_header())

func get(path, query=""):
	var request_path = _construct_path(path, query)
	return _request(HTTPClient.METHOD_GET, request_path, request_header)

func post(path, body=""):
	var request_path = _construct_path(path)
	return _request(HTTPClient.METHOD_POST, request_path, request_header, body)

func put(path, body=""):
	var request_path = _construct_path(path)
	return _request(HTTPClient.METHOD_PUT, request_path, request_header, body)

func delete(path, query=""):
	var request_path = _construct_path(path, query)
	return _request(HTTPClient.METHOD_DELETE, request_path, request_header)

func patch(path, body=""):
	var request_path = _construct_path(path)
	var header = request_header
	header.append("X-HTTP-Method-Override: PATCH")
	return _request(HTTPClient.METHOD_PUT, request_path, header, body)

func listen(path):
	var source = _create_source(path)
	if pool != null:
		var task = Task.new(source, "start")
		pool.add_task(task)
	else:
		pending.push_back({"object": source, "method": "start", "args": []})
	return source

func resume(object):
	if object != null: 
		var operation
		var i = -1
		for op in pending:
			i += 1
			if op["object"] == object:
				operation = op
				break
		if operation != null and i > -1:
			pending.remove(i)
			var obj = operation["object"]
			var method = operation["method"]
			var args = operation["args"]
			obj.callv(method, args)

func set_pool(thread_pool):
	pool = thread_pool

func set_auth(token):
	auth = token

func _construct_path(path, query=""):
	var request_path = str(path, ".json")
	if auth != null and not auth.empty():
		request_path = str(request_path, "?auth=", auth)
	if query != null and not query.empty():
		request_path = str(request_path, "&", query)
	return request_path

func _request(method, path, header=StringArray(), body=""):
	var request = _create_request()
	var args = [method, path, body, header]
	if pool != null:
		var task = Task.new(request, "request", args)
		pool.add_task(task)
	else:
		pending.push_back({"object": request, "method": "request", "args": args})
	return request

func _create_request():
	var request = Request.new(host)
	request.enable_ssl(true)
	request.connect("request_on_complete", self, "_request_on_complete")
	request.connect("request_on_error", self, "_request_on_error")
	return request

func _create_source(path):
	var source_path = _construct_path(path)
	var source = EventSource.new(host)
	source.enable_ssl(true)
	source.set_path(source_path)
	source.add_header(_get_user_agent_header())
	source.connect("source_on_event", self, "_source_on_event")
	source.connect("source_on_message", self, "_source_on_message")
	source.connect("source_on_close", self, "_source_on_close")
	source.connect("source_on_error", self, "_source_on_error")
	return source

func _get_user_agent_header():
	return "User-Agent: Godot Engine"

func _is_valid_json(string):
	return _is_valid_data(string, '{', '}')

func _is_valid_string(string):
	return _is_valid_data(string, '"', '"')

func _is_valid_data(string, str_first, str_last):
	var ok = false
	if string.length() > 1:
		var first = string[0]
		var last = string[string.length() - 1]
		if first == str_first and last == str_last:
			ok = true
	return ok

func _extract_string(string):
	if string.length() > 2:
		return string.substr(1, string.length() - 2)
	else:
		return string

func _get_response_info(response):
	var info
	var body = response.get_body()
	var string = body.get_string_from_utf8().strip_edges()
	if _is_valid_json(string):
		info = Dictionary()
		info.parse_json(string)
	elif _is_valid_string(string):
		info = _extract_string(string)
	else:
		if body.size() == 0 and response.has_error():
			info = response.get_error()
		else:
			if string.is_valid_integer():
				info = string.to_int()
			elif string.is_valid_float():
				info = string.to_float()
			elif string != "null":
				info = string
	return info

func _request_on_complete(request, response):
	var info = _get_response_info(response)
	emit_signal("firebase_on_success", self, request, info)

func _request_on_error(request, response):
	var info = _get_response_info(response)
	emit_signal("firebase_on_error", self, request, info)

func _source_on_event(source, id, event, data):
	emit_signal("firebase_on_stream", self, source, event, data)

func _source_on_message(source, id, data):
	emit_signal("firebase_on_stream", self, source, "message", data)

func _source_on_close(source):
	emit_signal("firebase_on_stop", self, source)

func _source_on_error(source, error):
	emit_signal("firebase_on_error", self, source, error)
