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


		
