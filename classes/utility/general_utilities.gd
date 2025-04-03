class_name GeneralUtilities
extends Node



static func normalize(val, min, max):
	return minmax((val - min) / (max - min), 0, 1)

static func minmax(value, min, max):
	var temp = max(value, min)
	var temp1 = min(temp, max)
	return min(max(value, min), max)

## Rounds numbers
static func rn(v: float, d: float = 0):
	var m: float = pow(10, d)
	var temp1: float = (v * m) / m	
	var temp: float = round(v * m) / m	# TEMP
	return round(v * m) / m	

## Convert a array of vectors to an array of arrays
## USed for classes/functions that take an array of arrays as a parameter, 
## for example, line_clip
static func convert_vector2_array_to_nested(vector2_array):
	var nested_array = []
	for vec in vector2_array:
		nested_array.append([vec.x, vec.y])
	return nested_array	
