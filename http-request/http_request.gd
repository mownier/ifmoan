
extends Reference

signal request_completed(request, response)
signal did_receive_data(request, data)
signal completed_with_error(request, response)
signal on_finish_listening(request)

var http_response = preload("http_response.gd")
var http_url = preload("http_url.gd")

var client = HTTPClient.new()
var host = "localhost"
var port = 80
var verify_host = true
var use_ssl = false
var keep_open = false
var max_redirect = 5
var redirect_count = 0
var requesting = false

var closed = false
var listening = false

func _init(p_host):
	host = p_host

func resume(method, path, body="", headers=StringArray()):
	_request(host, method, path, body, headers, use_ssl, verify_host)

func close():
	closed = true
	if not listening:
		client.close()

func enable_host_verification(enable):
	verify_host = enable

func enable_ssl(enable):
	if enable:
		port = 443
	use_ssl = enable

func is_host_verification_enabled():
	return verify_host

func is_ssl_enabled():
	return use_ssl

func _request(host, method, path, body="", headers=StringArray(), use_ssl=false, verify_host=true):
	requesting = true
	closed = false
	var response = _connect(host, port, use_ssl, verify_host)
	if response.error != null:
		close()
		emit_signal("completed_with_error", self, response)
	else:
		client.request(method, path, headers, body)
		response = _poll()
		var success = _validate_response(response)
		if not success:
			close()
			if response.error == null:
				response.error = str("Responded with status code: ", response.status_code)
			emit_signal("completed_with_error", self, response)
		else:
			var should_redirect = _will_redirect(response)
			if should_redirect:
				redirect_count += 1
				if redirect_count <= max_redirect:
					close()
					_redirect(response, method, body, headers)
				else:
					response.error = "Reached max redirect"
					close()
					emit_signal("completed_with_error", self, response)
			else:
				emit_signal("request_completed", self, response)
				if keep_open:
					_listen_stream_data()
				else:
					close()

func _connect(host, port, use_ssl, verify_host):
	client.connect(host, port, use_ssl, verify_host)
	return _poll()

func _poll():
	var status = -1
	var current_status
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
	var response = http_response.new()
	response.body = body
	response.content_length = client.get_response_body_length()
	response.status_code = client.get_response_code()
	response.headers = client.get_response_headers_as_dictionary()
	return response

func _construct_error_reponse(error):
	var response = http_response.new()
	response.error = error
	return response

func _validate_response(response):
	if (response.status_code >= 400 or
		response.error != null):
		return false
	else:
		return true

func _will_redirect(response):
	if (response.status_code == 301 or
		response.status_code == 302 or
		response.status_code == 307):
		return true
	else:
		return false

func _redirect(response, method, body, headers):
	var location = response.headers["Location"]
	var url = http_url.new(location)
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
		if scheme == "https":
			r_port = 443
			r_use_ssl = true
	
	_request(r_host, method, r_path, body, headers, r_use_ssl, verify_host)

func _listen_stream_data():
	print("http_request START listening")
	listening = true
	while (not closed and
			client.poll() == OK and
			client.get_status() == HTTPClient.STATUS_CONNECTED):
		var data = client.get_connection().get_data(1)
		var bytes = data[1]
		var err = data[0]
		if err == OK and bytes.size() > 0:
			emit_signal("did_receive_data", self, bytes)
	listening = false
	emit_signal("on_finish_listening", self)
	print("http_request FINISH listening")