#
## Port of https://github.com/mourner/tinyqueue/tree/main
#
class_name TinyQueue
extends Object

var data: Array = []
var length: int = 0
var compare: Callable

# Both arguments are optional. The Callable = Callable() is like 
# Calleble = null, letting you make the Callable optional.
func _init(data: Array = [], compare: Callable = Callable()) -> void:
	# Initialize the queue data and length
	self.data = data
	self.length = data.size()

	# Assign default comparison function if none is provided
	if not compare.is_valid():
		self.compare = func(a, b) -> int:
			if a < b:
				return -1
			elif a > b:
				return 1
			else:
				return 0
	else:
		self.compare = compare

	# Build the heap if there are elements in the array
	if self.length > 0:
		for i in range((self.length >> 1) - 1, -1, -1):
			_down(i)

# Push an item into the queue
func push(item):
	data.append(item)
	_up(length)
	length += 1

# Pop the top item (highest priority) from the queue
func pop() -> Variant:
	if length == 0:
		return null

	var top = data[0]
	var bottom = data.pop_back()
	length -= 1

	if length > 0:
		data[0] = bottom
		_down(0)

	return top

# Peek at the top item without removing it
func peek() -> Variant:
	return data[0] if length > 0 else null

# Helper method to maintain heap property by moving an element up
func _up(pos: int):
	var item = data[pos]

	while pos > 0:
		var parent = (pos - 1) >> 1
		var current = data[parent]
		if compare.callv([item, current]) >= 0:
			break
		data[pos] = current
		pos = parent

	data[pos] = item

# Helper method to maintain heap property by moving an element down
func _down(pos: int):
	var half_length = length >> 1
	var item = data[pos]

	while pos < half_length:
		var best_child = (pos << 1) + 1  # Initially the left child
		var right = best_child + 1

		if right < length and compare.callv([data[right], data[best_child]]) < 0:
			best_child = right
		if compare.callv([data[best_child], item]) >= 0:
			break

		data[pos] = data[best_child]
		pos = best_child

	data[pos] = item
