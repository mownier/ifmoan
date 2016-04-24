
extends Reference

signal request_on_complete(request, response)
signal request_on_receive(request, data)
signal request_on_error(request, response)
signal request_on_stop_streaming(request)

var HTTPResponse = preload("http_response.gd")
var HTTPUrl = preload("http_url.gd")

var requesting = false
var closed = false
var streaming = false
var redirect_count = 0

var client
var host setget ,get_host
var port setget ,get_port
var use_ssl setget enable_ssl
var verify_host setget should_verify_host
var keep_open setget should_keep_open
var max_redirect setget set_max_redirect

func _init(host="localhost", port=80, use_ssl=false):
	self.host = host
	self.port = port
	self.use_ssl = use_ssl
	self.client = HTTPClient.new()
	self.verify_host = true
	self.keep_open = false
	self.max_redirect = 5

func request(method, path, body="", headers=StringArray()):
	_request(host, method, path, body, headers, use_ssl, verify_host)

func close():
	closed = true
	if not streaming:
		client.close()

func should_verify_host(enable):
	verify_host = enable

func enable_ssl(enable):
	if enable:
		port = 443
	use_ssl = enable

func should_keep_open(condition):
	keep_open = condition

func set_max_redirect(count):
	max_redirect = count

func get_host():
	return host

func get_port():
	return port

func _request(host, method, path, body="", headers=StringArray(), use_ssl=false, verify_host=true):
	requesting = true
	closed = false
	var response = _connect(host, port, use_ssl, verify_host)
	if response.get_error() != null:
		close()
		emit_signal("request_on_error", self, response)
	else:
		client.request(method, path, headers, body)
		response = _poll()
		var success = _validate_response(response)
		if not success:
			close()
			if response.get_error() == null:
				var error = str("Responded with status code: ", response.get_status_code())
				response.set_error(error)
			emit_signal("request_on_error", self, response)
		else:
			var should_redirect = _will_redirect(response)
			if should_redirect:
				redirect_count += 1
				if redirect_count <= max_redirect:
					close()
					_redirect(response, method, body, headers)
				else:
					response.set_error("Reached max redirect")
					close()
					emit_signal("request_on_error", self, response)
			else:
				emit_signal("request_on_complete", self, response)
				if keep_open:
					_stream_data()
				else:
					close()

func _connect(host, port, use_ssl, verify_host):
	client.connect(host, port, use_ssl, verify_host)
	return _poll()

func _poll():
	var status = -1
	var current_status
	var started = OS.get_unix_time()
	while true:
		client.poll()
		current_status = client.get_status()
		if status != current_status:
			status = current_status
			if status == HTTPClient.STATUS_DISCONNECTED:
				return _construct_error_reponse("Disconnected from host")
			if status == HTTPClient.STATUS_CANT_RESOLVE:
				return _construct_error_reponse("Cannot resolve host")
			if status == HTTPClient.STATUS_CANT_CONNECT:
				return _construct_error_reponse("Cannot connect to host")
			if status == HTTPClient.STATUS_CONNECTION_ERROR:
				return _construct_error_reponse("Connection error")
			if status == HTTPClient.STATUS_SSL_HANDSHAKE_ERROR:
				return _construct_error_reponse("SSL handshake error")
			if status == HTTPClient.STATUS_RESOLVING:
				continue
			if status == HTTPClient.STATUS_CONNECTING:
				continue
			if status == HTTPClient.STATUS_REQUESTING:
				continue
			if status == HTTPClient.STATUS_CONNECTED:
				return _construct_response(status)
			if status == HTTPClient.STATUS_BODY:
				return _parse_body()

func _parse_body():
	var body = client.read_response_body_chunk()
	var response = _construct_response(body)
	return response

func _construct_response(body):
	var status_code = client.get_response_code()
	var header = client.get_response_headers_as_dictionary()
	var response = HTTPResponse.new(body, status_code, header)
	return response

func _construct_error_reponse(error):
	var response = HTTPResponse.new()
	response.set_error(error)
	return response

func _validate_response(response):
	if (response.get_status_code() >= 400 or
		response.get_error() != null):
		return false
	else:
		return true

func _will_redirect(response):
	var status_code = response.get_status_code()
	if status_code== 301 or status_code == 302 or status_code == 307:
		return true
	else:
		return false

func _redirect(response, method, body, headers):
	var location = response.get_header()["Location"]
	var url = HTTPUrl.new(location)
	var segments = url.parse_segments()
	
	var r_path = location
	var r_host = host
	var r_use_ssl = use_ssl
	var r_port = port
	
	if segments.has("path"):
		r_path = segments["path"]
		if segments.has("query"):
			r_path += segments["query"]
	
	if segments.has("host"):
		r_host = segments["host"]
	
	if segments.has("port"):
		r_port = int(segments["port"])
	
	if segments.has("scheme"):
		var scheme = segments["scheme"]
		if url.is_ssl_enable(scheme):
			r_port = 443
			r_use_ssl = true
	
	_request(r_host, method, r_path, body, headers, r_use_ssl, verify_host)

func _stream_data():
	streaming = true
	while not closed:
		var data = client.get_connection().get_data(1)
		var bytes = data[1]
		var err = data[0]
		if err == OK:
			if bytes.size() > 0:
				emit_signal("request_on_receive", self, bytes)
		else:
			break
	streaming = false
	emit_signal("request_on_stop_streaming", self)
	close()
