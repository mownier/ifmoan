
extends Reference

var body setget ,get_body
var status_code setget ,get_status_code
var header setget ,get_header
var error setget set_error,get_error

func _init(body=RawArray(), status_code=0, header=[]):
	self.body = body
	self.status_code = status_code
	self.header = header

func get_body():
	return body

func get_status_code():
	return status_code

func get_header():
	return header

func has_error():
	if error == null:
		return false
	else:
		return true

func set_error(what):
	error = what

func get_error():
	return error