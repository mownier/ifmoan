# https://www.safaribooksonline.com/library/view/regular-expressions-cookbook/9781449327453/ch08s08.html
extends Reference

var url_string

func _init(url):
	url_string = url

func parse_segments():
	var segments = {}
	if is_valid():
		var pattern = "([a-z][a-z0-9+\\-.]*):\/\/([a-z0-9\\-._~%!$&\'()*+,;=]+@)?([a-z0-9\\-._~%]+|\\[[a-f0-9:.]+\\]|\\[v[a-f0-9][a-z0-9\\-._~%!$&\'()*+,;=:]+\\])(:[0-9]+)?([a-z0-9\\-._~%!$&\'()*+,;=:@\/]*)(\\?[a-z0-9\\-._~%!$&\'()*+,;=:@\/?]*)?(\\#[a-z0-9\\-._~%!$&\'()*+,;=:@\/?]*)?"
		var regex = RegEx.new()
		regex.compile(pattern)
		if regex.is_valid():
			regex.find(url_string)
			for i in range(regex.get_captures().size()):
				if i > 0:
					var segment = regex.get_capture(i)
					if segment.empty():
						continue
					if i == 1:
						segments["scheme"] = segment
					elif i == 2:
						if segment.length() > 1:
							segments["user"] = segment.substr(0, segment.length() - 1)
					elif i == 3:
						segments["host"] = segment
					elif i == 4:
						if segment.length() > 1:
							segments["port"] = int(segment.substr(1, segment.length() - 1))
					elif i == 5:
						if segment.empty():
							segments["path"] = "/"
						else:
							segments["path"] = segment
					elif i == 6:
						if segment.length() > 1:
							segments["query"] = segment.substr(1, segment.length() - 1)
					elif i == 7:
						if segment.length() > 1:
							segments["fragment"] = segment.substr(1, segment.length() - 1)
	return segments

func is_valid():
	var pattern = "([a-z][a-z0-9+\\-.]*:(\/\/([a-z0-9\\-._~%!$&\'()*+,;=]+@)?([a-z0-9\\-._~%]+|\\[[a-f0-9:.]+\\]|\\[v[a-f0-9][a-z0-9\\-._~%!$&\'()*+,;=:]+\\])(:[0-9]+)?(\/[a-z0-9\\-._~%!$&\'()*+,;=:@]+)*\/?|(\/?[a-z0-9\\-._~%!$&\'()*+,;=:@]+(\/[a-z0-9\\-._~%!$&\'()*+,;=:@]+)*\/?)?)|([a-z0-9\\-._~%!$&\'()*+,;=@]+(\/[a-z0-9\\-._~%!$&\'()*+,;=:@]+)*\/?|(\/[a-z0-9\\-._~%!$&\'()*+,;=:@]+)+\/?))(\\?[a-z0-9\\-._~%!$&\'()*+,;=:@\/?]*)?(\\#[a-z0-9\\-._~%!$&\'()*+,;=:@\/?]*)?"
	var regex = RegEx.new()
	regex.compile(pattern)
	regex.find(url_string)
	if regex.get_capture_count() > 0 and regex.get_capture(0) == url_string:
		return true
	else:
		return false

func is_ssl_enabled(scheme):
	if scheme == "https":
		return true
	else:
		return false