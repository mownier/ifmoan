
extends WindowDialog

const TEST_SUCCESS = 0
const TEST_FAIL = 1
const TEST_EXPECTING = 2

onready var container = get_node("container")
onready var list = get_node("container/list")
onready var overall = get_node("container/overall")

var items = Array()

var icon_success = preload("success.png")
var icon_fail = preload("fail.png")
var icon_expecting = preload("expecting.png")
var icon_started = preload("started.png")

func _ready():
	var root_size = get_size()
	container.set_size(root_size)

func appear():
	popup_centered()

func add_test_suite(test_suite):
	var item = Item.new()
	item.set_suite(test_suite)
	items.push_back(item)
	
	list.add_item(test_suite, null, false)

func add_test_case(test_suite, test_case):
	var item = Item.new()
	item.set_suite(test_suite)
	item.set_case(test_case)
	items.push_back(item)
	
	list.add_item(test_case, icon_started, false)

func update_test_case(test_suite, test_case, status):
	var index = find_case(test_suite, test_case)
	var icon = get_updated_icon(status)
	list.set_item_icon(index, icon)

func add_overall_info(info):
	overall.add_item(info, null, false)

func find_case(test_suite, test_case):
	var index = -1
	
	for item in items:
		index += 1
		if item.is_valid() and item.is_case():
			if (item.get_case() == test_case and 
				item.get_suite() == test_suite):
				break
	
	return index

func get_updated_icon(status):
	if status == TEST_SUCCESS:
		return icon_success
	elif status == TEST_FAIL:
		return icon_fail
	elif status == TEST_EXPECTING:
		return icon_expecting
	else:
		return null

class Item extends Reference:
	
	var case
	var suite
	
	func set_case(c):
		case = c
	
	func set_suite(s):
		suite = s
	
	func get_suite():
		return suite
	
	func get_case():
		return case
	
	func is_case():
		if (case != null and 
			not case.empty() and
			suite != null and
			not suite.empty()):
			return true
		else:
			return false
	
	func is_suite():
		if (suite != null and
			not suite.empty() and
			(case == null or case.empty())):
			return true
		else:
			return false
	
	func is_valid():
		if is_suite() or is_case():
			return true
		else:
			return false