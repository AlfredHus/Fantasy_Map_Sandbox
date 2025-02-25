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
	
	return line_clip.polygon_clip(points, [0, 0, graph_width, graph_height])

# Creata a unique array
func unique(points: Array)-> Array:
	var out = []
	
	for p in points:
		if out.find(p) != -1:
			out.append(p)	
			
	return out
