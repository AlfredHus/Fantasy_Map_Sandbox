#
## Port of https://github.com/eqmiller/polylabel-csharp/tree/main
# https://github.com/eqmiller/polylabel-csharp/blob/main/src/Polylabel-CSharp/Cell.cs
#
class_name Cell
	
var x: float
var y: float
var h: float
var d: float
var max: float

func _init(x: float, y: float, h: float, polygon: Array):
	self.x = x
	self.y = y
	self.h = h
	self.d = self.point_to_polygon_dist(x, y, polygon)
	self.max = self.d + self.h * sqrt(2)

# Signed distance from point to polygon outline (negative if outside)
func point_to_polygon_dist(x: float, y: float, polygon: Array) -> float:
	var inside = false
	var min_dist_sq = INF

	for ring in polygon:
		var len = ring.size()
		var j = len - 1
		for i in range(len):
			var a = ring[i]
			var b = ring[j]

			if (a[1] > y) != (b[1] > y) and (x < (b[0] - a[0]) * (y - a[1]) / (b[1] - a[1]) + a[0]):
				inside = !inside

			min_dist_sq = min(min_dist_sq, self.get_seg_dist_sq(x, y, a, b))
			j = i

	return (1 if inside else -1) * sqrt(min_dist_sq)

	# Get squared distance from a point to a segment
func get_seg_dist_sq(px: float, py: float, a: Vector2, b: Vector2) -> float:
	var x = a[0]
	var y = a[1]
	var dx = b[0] - x
	var dy = b[1] - y

	if dx != 0 or dy != 0:
		var t = ((px - x) * dx + (py - y) * dy) / (dx * dx + dy * dy)

		if t > 1:
			x = b[0]
			y = b[1]
		elif t > 0:
			x += dx * t
			y += dy * t

	dx = px - x
	dy = py - y

	return dx * dx + dy * dy
