# https://www.safaribooksonline.com/library/view/regular-expressions-cookbook/9781449327453/ch08s08.html
extends Reference

var url_string

func _init(url):
	url_string = url

func _get_segment(pattern):
	var regex = RegEx.new()
	regex.compile(pattern)
	regex.find(url_string)
	if regex.get_capture_count() > 0:
		var last = regex.get_capture_count() - 1
		return regex.get_capture(last)
	else:
		return ""

func parse_segments():
	var segments = {}
	
	var scheme = get_scheme()
	var user = get_user()
	var host = get_host()
	var port = get_port()
	var path = get_path()
	var query = get_query()
	var fragment = get_fragment()
	
	if not scheme.empty():
		segments["scheme"] = scheme
	if not user.empty():
		segments["user"] = user
	if not host.empty():
		segments["host"] = host
	if not port.empty():
		segments["port"] = int(port)
	if not path.empty():
		segments["path"] = path
	if not query.empty():
		segments["query"] = query
	if not fragment.empty():
		segments["fragment"] = fragment
	
	return segments

func is_ssl_enabled(scheme):
	if scheme == "https":
		return true
	else:
		return false

func get_scheme():
	var pattern = "^([a-z][a-z0-9+\\-.]*):"
	return _get_segment(pattern)

func get_user():
	var pattern = "^[a-z0-9+\\-.]+:\/\/([a-z0-9\\-._~%!$&\'()*+,;=]+)@"
	return _get_segment(pattern)

func get_host():
	var pattern = "^[a-z][a-z0-9+\\-.]*:\/\/([a-z0-9\\-._~%!$&\'()*+,;=]+@)?([a-z0-9\\-._~%]+|\u21B5\r\n\\[[a-z0-9\\-._~%!$&\'()*+,;=:]+\\])"
	return _get_segment(pattern)

func get_port():
	var pattern = "^[a-z][a-z0-9+\\-.]*:\/\/([a-z0-9\\-._~%!$&\'()*+,;=]+@)?([a-z0-9\\-._~%]+|\\[[a-z0-9\\-._~%!$&\'()*+,;=:]+\\]):([0-9]+)"
	return _get_segment(pattern)

func get_path():
	var pattern = "([a-z][a-z0-9+\\-.]*:(\/\/[^\/?#]+)?)?([a-z0-9\\-._~%!$&\'()*+,;=:@\/]*)"
	var path = _get_segment(pattern)
	if not path.empty() and path.begins_with("/"):
		return path
	else:
		return "/"

func get_query():
	var pattern = "^[^?#]+\\?([^#]+)"
	return _get_segment(pattern)

func get_fragment():
	var pattern = "#(.+)"
	return _get_segment(pattern)