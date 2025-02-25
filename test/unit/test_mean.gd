# Test the mean. Used test examples from d3.
# https://observablehq.com/@d3/d3-mean-d3-median-and-friends
extends GutTest

# Test mean of valid numbers
func test_mean_value_for_numbers():

	assert_eq(Statistics.mean([1]), 1.0)
	assert_eq(Statistics.mean([5, 1, 2, 3, 4]), 3.0)
	assert_eq(Statistics.mean([20,3]), 11.5)
	assert_eq(Statistics.mean([3,20]), 11.5)

# Test the handling of null and NAN
func test_ignore_null_NAN():
	assert_eq(Statistics.mean([NAN, 1, 2, 3, 4, 5]), 3.0)
	assert_eq(Statistics.mean([1, 2, 3, 4, 5, NAN]), 3.0)
	assert_eq(Statistics.mean([10, null, 3, null, 5, NAN]), 6.0)

func test_no_observed_values():
	assert_eq(Statistics.mean([]), 0.0)
	assert_eq(Statistics.mean([null]), 0.0)
	assert_eq(Statistics.mean([NAN]), 0.0)
	assert_eq(Statistics.mean([NAN, NAN]), 0.0)

func test_coerces_values_to_numbers():
	var numbers = [83, 32, 14, 52, 31, 66, 12, 11, 0, 78, 60, 97, 47, 37, 91, 58, 48, 55, 98, 45, 
	64, 1, 17, 39, 82, 24, 5, 40, 61, 27, 57, 34, 56, 26, 30, 36, 43, 80, 85, 68, 75, 50, 59, 44, 
	18, 19, 88, 87, 41, 90, 4, 81, 94, 89, 93, 22, 3, 67, 13, 35, 96, 16, 7, 15, 20, 76, 63, 49, 
	25, "95", 86, 99, 28, 62, 71, null, 21, 10, 72, 29, 51, 46, 73, 74, 9, 65, 77, 92, 6, 8, 2, 
	79, 53, 69, 70, 33, 54, 42, 23, 84, 38, NAN, "Fred"]
	
	assert_eq(Statistics.mean(["1"]), 1.0)	
	assert_eq(Statistics.mean(["5", "1", "2", "3", "4"]), 3.0)
	assert_eq(Statistics.mean(["20", "3"]), 11.5)	
	assert_eq(Statistics.mean(["3", "20"]), 11.5)
	assert_eq(Statistics.mean(["String"]), 0.0)	
	assert_eq(Statistics.mean(["12xd3"]), 12.0)
	assert_eq(Statistics.mean(["x12xd3","x12xd3"]), 0.0)
	assert_eq(Statistics.mean(["x12xd3","x12xd3", "12xd3", "20"]), 16.0)
	assert_eq(Statistics.mean(numbers), 49.5)

## Keep this code here for npw. 
func _test_value(value:Variant):
	if value == null:
		print("Value is null, no number conversion attempted")
		return
		
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		var float_value : float = float(value)
		print("Value is a valid number: ", float_value)
	elif typeof(value) == TYPE_STRING:
		var parsed_number : Variant = parse_leading_number(value)
		if parsed_number != null:
			print("Value is a valid number: ", parsed_number)
		else:
			print("Value is not a valid number (or NaN)")
	else:
		print("Value is not a valid number (or NaN)")


# Function to simulate JavaScript undefined
func _get_undefined_value() -> Variant:
	return null

func is_valid_float(str : String) -> bool:
	var result : float
	var is_ok : bool
	result = str.to_float()
	is_ok = str.is_valid_float()
	if not is_ok:
		return false
	return true
	
func parse_leading_number(str:String) -> Variant:
	var parsed_string = ""
	for char in str:
		if (char >= "0" and char <= "9") or char == ".":
			parsed_string += char
		else:
			break
	
	if parsed_string.is_empty():
		return null
	
	if parsed_string.is_valid_float():
		return parsed_string.to_float()
		
	return null
