class_name GeneralUtilities
extends Node



static func normalize(val, min, max):
	return minmax((val - min) / (max - min), 0, 1)

static func minmax(value, min, max):
	return min(max(value, min), max)

static func rn(v, d = 0):
	var m = pow(10, d)
	var temp1 = (v * m) / m	
	var temp = round(v * m) / m	# TEMP
	return round(v * m) / m	


		
