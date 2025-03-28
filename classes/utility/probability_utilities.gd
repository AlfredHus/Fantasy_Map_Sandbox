#
## Code from Azgaar's Fantasy Map Generator
## Ported from https://github.com/Azgaar/Fantasy-Map-Generator
#
# https://github.com/Azgaar/Fantasy-Map-Generator/blob/5bb33311fba48ed83f797c77779dbb909d6e1958/utils/probabilityUtils.js
#
class_name ProbabilityUtilities
## Get a number from a string in the format "1-3", "2", or "0.5"
## 
## This function takes a number (float or integer) or range which is passed in as a 
## string and returns a random float.
## For ranges, the range will be in the form of "90-99", a lower and uppper range separated
## by a "-" (dash),
## In this case, we separate the lower and upper values and use them tro generate a random float 
## between the two values.
## For all other cases, we return a random float based on the number passed in.
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

	# If we are here, then we should have a range, like 1 - 10. We look for the 
	# dash and then extract the lower and upper values.
	var numbered_range: PackedStringArray = r.split("-")
	if numbered_range.size() == 0:
		print("Cannot parse the number. Check the format", numbered_range)
		return 0.0

	#var count: float = randf_range(float(range[0]) * sign, float(range[1]))
	# Create a random value between the lower and upper range
	# What this cannot handle is a negative range. I don't thnk we need
	# that. May need to fix if in fact we want to handle negative ranges.
	var number_in_range: float = randf_range(float(numbered_range[0]), float(numbered_range[1]))
	if is_nan(number_in_range) or number_in_range< 0.0:
		print("Cannot parse number. Check the format:", numbered_range)
		return 0.0

	return number_in_range	
	

## Probability shorthand
static func P(probability) -> float:
	if probability >= 1.0:
		return true
	if probability <= 0:
		return false
	return randf() < probability

## R6andom number in a range
static func rand(min = null, max = null):
	# If neither parameter is provided, return a float between 0 and 1.
	if min == null and max == null:
		return randf()
	# If only one parameter is provided, treat it as the maximum.
	if max == null:
		max = min
		min = 0
	# Calculate a random integer in the range [min, max].
	# randf() returns a float between 0 and 1.
	# Multiply by (max - min + 1) to cover the range of integers and floor the result.
	return int(floor(randf() * (max - min + 1))) + min
	
# Random Gaussian number generator
# expected - expected value
# deviation - standard deviation
# minimum - minimum value
# maximum: - maximum value
# round_to - round value to n decimals
# Returns random number
static func gauss(expected: float = 100.0, deviation: float = 30.0, minimum: int = 0, maximum: int = 300, round_to: int = 0):
	# randf is for normally distributed random numbers
	var random_value = randfn(expected, deviation)  # Gaussian distribution
	var min_max_value = GeneralUtilities.minmax(random_value, minimum, maximum)
	var rounded_value = GeneralUtilities.rn(min_max_value, round_to)
	
	return rounded_value
	
	# Returned as one line. Breakdown above is for easier debugging
	# return GeneralUtilities.rn(GeneralUtilities.minmax(randfn(expected, deviation), min, max), round_to);
