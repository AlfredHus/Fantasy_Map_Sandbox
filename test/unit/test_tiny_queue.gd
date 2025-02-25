#
## Port of https://github.com/mourner/tinyqueue/tree/main test code
#
extends GutTest

#const TinyQueue := preload("res://classes/utility/tiny_queue.gd")
var queue: TinyQueue

# Custom comparitor to use for tests
func custom_compare(a: int, b: int) -> int:
	return a - b

# Tests the creation of a queue without passing in an array, ie.e., manually
# added in the values to the array
func test_tiny_queue_no_array() -> void:
	# create an empty priority queue
	queue = TinyQueue.new()
	queue.push(7)
	queue.push(5)
	queue.push(10)
	
	# remove the top item
	var top = queue.pop() # returns 5
	assert_eq(top, 5, "Popped value should be 5")
	
	# return the top item (without removal)
	top = queue.peek() # returns 7
	assert_eq(top, 7, "Popped value should be 5")
	
# Tests the creation a priority queue from an existing 
# array (modifies the array)
func test_tiny_queue_existing_array() -> void:
	queue = TinyQueue.new([7, 5, 10])
	
	# remove the top item
	var top = queue.pop() # returns 5
	assert_eq(top, 5, "Popped value should be 5")
	
	# return the top item (without removal)
	top = queue.peek() # returns 7
	assert_eq(top, 7, "Popped value should be 5")
	
func test_tiny_queue_custom_comparetor() -> void:
	var queue = TinyQueue.new([7, 5, 10], Callable(self, "custom_compare"))
	
		# remove the top item
	var top = queue.pop() # returns 5
	assert_eq(top, 5, "Popped value should be 5")
	
	# return the top item (without removal)
	top = queue.peek() # returns 7
	assert_eq(top, 7, "Popped value should be 5")
	
# Tests edge cases with a few elements
func test_tiny_queue_edge_cases() -> void:
	var queue = TinyQueue.new()
	
	queue.push(2);
	queue.push(1);
	queue.pop();
	queue.pop();
	queue.pop();
	queue.push(2);
	queue.push(1);
	
	var top = queue.pop()
	assert_eq(top, 1, "Expected a value of 1")
	top = queue.pop()
	assert_eq(top, 2, "Expected a value of 2")
	top = queue.pop()
	assert_eq(top, null, "Expected a value of null")
		

# Tests the initialization of an empty array
func test_tiny_queue_empty_queue() -> void:
	var queue = TinyQueue.new([])	
	
	assert_eq(queue.data, [], "Expected empty array")
		
