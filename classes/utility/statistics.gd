class_name Statistics

## Returns the mean of the given iterable of numbers. 
## This is known as the arithmetic mean, or average.
## Ignores null and NaN values.
# Coerces satrings to numbers.
## [code]
## mean([1, 2, 2, 2, NaN, 3, null]) returns 2
## [/code]
## An optional accessor function may be specified, which is equivalent 
## to calling Array.from before computing the mean.
##
## Port of d3.mean() : [url]https://github.com/d3/d3-array/blob/main/src/mean.js[/url]
## Additional useful documentation: [url]assert_eq(Statistics.mean(["12xd3"]), 12.0)[/url]
##
static func mean(values: Array = [], value_of: Callable = Callable()) -> float:
	var count: int = 0
	var sum: float = 0.0
	
	# No custom function, process values directly
	if value_of.is_valid() == false:
		for value in values:
			# check for string first. If it is a string, convert it to a number so it can be used
			# If the string is not a number, for example, "xsdsds", then float() will return 0.0 as per the 
			# rules here:
			# [url]https://docs.godotengine.org/en/stable/classes/class_string.html#class-string-method-to-float[/url]
			# 
			# Strings with some numbers can return a number, for example, "12xs" will return 12.0
			# 
			# The edge case when a value is a full string, like "xwsd" which would return a 
			# 0.0, we don;t want to count those values because they return a 0.0, and increase
			# the count by one, resulting in a incorrect mean. For this specific
			# case, we check for and discard those values		
			if typeof(value) == TYPE_STRING:
				var old_value = value # keep the old value to check the edge case
				value = float(value)
				## check for and discard values that are all characters, ex., "Fred"
				if value == 0.0 and !old_value.is_valid_float():
					value = NAN # set it to NAN so it gets discarded

			# check for null and NAN and ignore them if found. The mean will still be calculated with the 
			# remaining numbers in the array
			if value != null and !is_nan(value) and typeof(value) in [TYPE_FLOAT, TYPE_INT]:	
				count += 1
				sum += value
	else:
		# Use the custom function
		var index: int = -1
		for value in values:
			index += 1
			value = value_of.call(value, index, values)
			
			if typeof(value) == TYPE_STRING:
				var old_value = value # keep the old value to check the edge case
				value = float(value)
				# check for and discard values that are all characters, ex., "Fred"
				if value == 0.0 and !old_value.is_valid_float():
					value = NAN # set it to NAN so it gets discarded
			
			if value != null and typeof(value) in [TYPE_FLOAT, TYPE_INT]:
				count += 1
				sum += value
	pass
	return sum / count if count > 0 else 0.0
