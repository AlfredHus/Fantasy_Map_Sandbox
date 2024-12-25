class_name ProbabilityUtilities



# Get a number from a string in the format "1-3", "2", or "0.5"
# This function takes a number (float or integer) or range which is passed in as a 
# string and returns a random float.
# For ranges, the range will be in the form of "90-99", a lower and uppper range separated
# by a "-" (dash),
# IN this case, we separate the lower and upper values and use them tro generate a random float 
# between the two values.
# For all other cases, we return a random float based on the number passed in.
static func get_number_in_range(r: String) -> float:
	
	# Check to make sure what is passed in is a string. Not sure this is 
	# necessary. The function is static typed, so we should get a compiler
	# error if we try to pass in something that is not a String. 
	# TODO: Leave it for now since its in the original code, but remove it
	# when you verify that it is not needed.
	if typeof(r) != TYPE_STRING:
		print("Range value should be a string:", r)
		return 0
	
	# One of the use cases is where we pass in a string value that is just a 
	# number and not a range. Check that here if that is the case, return 
	# a random float value based on the string value	
	# This will handle integers, floats and negative numbers.
	if r.is_valid_float():
		return float(r)
	
	# This code is to handle negative numbers as strings, for example, -2.
	#var sign = 1
	#if r[0] == "-":
		#sign = -1
##
	#if r[0] == "-" or not r[0].is_valid_int():
		#r = r.substr(1)

	# If we are here, then we should ahve a range, like 1 - 10. We look for the 
	# dash and then extract the lower and upwer values.
	var range = r.split("-")
	if range.size() == 0:
		print("Cannot parse the number. Check the format", range)
		return 0

	#var count: float = randf_range(float(range[0]) * sign, float(range[1]))
	# Create a random value between the lower and upper range
	# What this cannot handle is a negative range. I don't thnk we need
	# that. May need to fix if in fact we want to handle negative ranges.
	var count: float = randf_range(float(range[0]), float(range[1]))
	if is_nan(count) or count < 0:
		print("Cannot parse number. Check the format:", range)
		return 0

	return count	
	

static func P(probability) -> float:
	if probability >= 1.0:
		return true
	if probability <= 0:
		return false
	return randf() < probability
