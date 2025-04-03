class_name CommonUtils
extends Node

var line_clip: LineClip
	
func _init():
	line_clip = LineClip.new()
	
func clip_poly(points: Array, graph_width: int, graph_height: int, secure: int = 0):
	if (points.size() < 2):
		return points
		
	for point in points:
		if point == null:
			push_error("Undefined point in clip_poly: " + str(points))
			return points
		# the points array is an array of vector2. line_clip takes the 
		# points parameter as a array of arrays. so we need to convert 
		# it
		# Array of vectors looks like this [(12, 12), (54, 15)],  an array
		# of arrays looks like this [[12, 12], [54, 15]]. 
	var nested_points: Array
	nested_points = GeneralUtilities.convert_vector2_array_to_nested(points)

	return line_clip.polygon_clip(nested_points, [0, 0, graph_width, graph_height])

# Creata a unique array
func unique(points: Array)-> Array:
	var out = []
	
	for p in points:
		if out.find(p) != -1:
			out.append(p)	
			
	return out
