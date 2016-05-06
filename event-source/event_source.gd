
extends Reference

signal source_on_open(source)
signal source_on_message(source, id, data)
signal source_on_error(source, error)
signal source_on_event(source, id, event, data)
signal source_on_close(source)

const STATE_CONNECTING = 0
const STATE_OPEN = 1
const STATE_CLOSED = 2
const STATE_CLOSING = 3

const RECONNECT_MAX = 5

var Request = preload("../http-request/http_request.gd")

var http_request
var last_event_id
var ready_state = STATE_CLOSED
var path = "/"
var received_buffer = RawArray()
var reconnect_count = 0
var retry_time = 3000 # 3 seconds
var headers = ["Accept: text/event-stream"]

func _init(host, port=80):
	self.http_request = _create_request(host, port)

func _create_request(host, port=80):
	var request = Request.new(host, port)
	request.connect("request_on_complete", self, "_request_on_complete")
	request.connect("request_on_receive", self, "_request_on_receive")
	request.connect("request_on_error", self, "_request_on_error")
	request.connect("request_on_stop_streaming", self, "_request_on_stop_streaming")
	request.should_keep_open(true)
	return request

func _request_on_complete(request, response):
	ready_state = STATE_OPEN
	emit_signal("source_on_open", self)

func _request_on_error(request, response):
	stop()
	if reconnect_count <= RECONNECT_MAX:
		var error = response.get_error()
		if (response.get_body() != null and 
			response.get_body().size() > 0):
			error = response.get_body().get_string_from_utf8()
		emit_signal("source_on_error", self, error)
		OS.delay_msec(retry_time)
		_reconnect()
	else:
		emit_signal("source_on_error", self, "Reached max reconnections.")

func _request_on_receive(request, data):
	if ready_state == STATE_OPEN:
		if data.size() > 0:
			for d in data:
				received_buffer.push_back(d)
			var events = _extract_events()
			_parse_events(events)

func _request_on_stop_streaming(request):
	ready_state = STATE_CLOSED
	emit_signal("source_on_close", self)

func _extract_events():
	var size = received_buffer.size()
	if (size > 1 and
		received_buffer[size - 1] == 10 and
		received_buffer[size - 2] == 10):
		var events = received_buffer.get_string_from_utf8().split("\n\n", false)
		received_buffer.resize(0)
		return events
	else:
		return StringArray()

func _parse_events(events):
	if events.size() < 1:
		return
	
	for event_string in events:
		var evt = _parse_event(event_string)
		if evt.has("id"):
			last_event_id = evt["id"].strip_edges()
		if evt.has("data"):
			var data = evt["data"].strip_edges()
			if not evt.has("event"):
				emit_signal("source_on_message", self, last_event_id, data)
			else:
				var event = evt["event"].strip_edges()
				emit_signal("source_on_event", self, last_event_id, event, data)

func _parse_event(event_string):
	var event = {}
	for line in event_string.split("\n", false):
		var colon_index = line.find(":")
		var key = line.left(colon_index)
		var value = line.right(colon_index + 1)
		if not key.empty():
			if key == "retry":
				retry_time = int(value)
			else:
				event[key] = value
	return event

func _reconnect():
	reconnect_count += 1
	start()

func enable_ssl(enable):
	http_request.enable_ssl(enable)

func add_header(header):
	headers.push_back(header)

func set_path(what):
	path = what

func get_state():
	return ready_state

func start():
	ready_state = STATE_CONNECTING
	http_request.request(HTTPClient.METHOD_GET, path, "", headers)

func stop():
	ready_state = STATE_CLOSING
	http_request.close()
