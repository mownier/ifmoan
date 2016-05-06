
extends Reference

var path
var key
var writer = File.new()
var reader = File.new()

func _init(path, key=""):
	self.path = path
	self.key = key

func write(data, append=true):
	var content = ""
	if append:
		content += read()
	writer.open(path, File.WRITE)
	content += str(data)
	writer.store_string(content)
	writer.close()

func read():
	var data = ""
	if reader.file_exists(path):
		reader.open(path, File.READ)
		data = reader.get_as_text()
	if reader.is_open():
		reader.close()
	return data
