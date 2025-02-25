extends GutTest
# Ported from MapBox tests
# https://github.com/mapbox/lineclip/blob/main/test.js
#

var line_clip: LineClip

func  before_all():
	line_clip = LineClip.new()

# Basic test - clips line
func test_line_clip():
	var points = [[-10, 10], [10, 10], [10, -10]] # line
	var bbox = [0, 0, 20, 20] # bbox
	var expected_result = [[[0, 10], [10, 10], [10, 0]]]
	var result = line_clip.line_clip(points, bbox)
	
	assert_eq(result, expected_result)
	
# When the entire polyline is inside the bbox, the result should be a single part identical 
# to the input.
func test_line_clip_inside():
	var points = [[2, 2], [3, 3], [4, 4]]
	var bbox = [0, 0, 10, 10]
	var expected_result = [[[2, 2], [3, 3], [4, 4]]]
	
	var result = line_clip.line_clip(points, bbox)
	
	assert_eq(result, expected_result, "Polyline completely inside the bbox should be unchanged.")
#
## Basic test - clips line
func test_line_clip_basic():
	var points = [[-10, 10], [10, 10], [10, -10], [20, -10], [20, 10], [40, 10],
		[40, 20], [20, 20], [20, 40], [10, 40], [10, 20], [5, 20], [-10, 20]]
	var bbox = [0, 0, 30, 30]
	var expected_result = [
		[[0, 10], [10, 10], [10, 0]],
		[[20, 0], [20, 10], [30, 10]],
		[[30, 20], [20, 20], [20, 30]],
		[[10, 30], [10, 20], [5, 20], [0, 20]]]
	
	var result = line_clip.line_clip(points, bbox)	
	
	assert_eq(result, expected_result)
	
#  Test clips line crossing through many times
func test_clips_many_times():
	var points = [[10, -10], [10, 30], [20, 30], [20, -10]]
	var bbox = [0, 0, 20, 20]
	var expected_result = [
		[[10, 0], [10, 20]],
		[[20, 20], [20, 0]]]
		
	var result = line_clip.line_clip(points, bbox)	
	
	assert_eq(result, expected_result)
	
# Clips polygon
func test_clips_polygon():
	var points = [[-10, 10], [0, 10], [10, 10], [10, 5], [10, -5], [10, -10], [20, -10],
		[20, 10], [40, 10], [40, 20], [20, 20], [20, 40], [10, 40], [10, 20], [5, 20], [-10, 20]]
	var bbox = [0, 0, 30, 30]
	var expected_result = [[[0, 10], [0, 10], [10, 10], [10, 5], [10, 0]], [[20, 0], [20, 10], [30, 10]],
		[[30, 20], [20, 20], [20, 30]], [[10, 30], [10, 20], [5, 20], [0, 20]]]
		
	var result = line_clip.line_clip(points, bbox)	
	
	assert_eq(result, expected_result)
	
# Test appends result if passed a third argument. Tests appending an empty array and an 
# array with values
func test_append_result():
	var arr = []
	var points = [[-10, 10], [30, 10]]
	var bbox = [0, 0, 20, 20]
	var expected_result = [[[0, 10], [20, 10]]]
	
	var result = line_clip.line_clip(points, bbox, arr)	
	
	assert_eq(result, expected_result)
	
	# Now append a array with values
	points = [[10, -10], [10, 30]]
	arr = [[20, 30], [20, -10]]
	bbox = [0, 0, 20, 20]
	expected_result =  [[20, 30], [20, -10], [[10, 0], [10, 20]]]
		
	result = line_clip.line_clip(points, bbox, arr)	
	
	assert_eq(result, expected_result)	
	
func test_floating_point_lines():
	var line = [ [-86.66015624999999, 42.22851735620852], [-81.474609375, 38.51378825951165], [-85.517578125, 37.125286284966776],
		[-85.8251953125, 38.95940879245423], [-90.087890625, 39.53793974517628], [-91.93359375, 42.32606244456202],
		[-86.66015624999999, 42.22851735620852]]
	var bbox = [-91.93359375, 42.29356419217009, -91.7578125, 42.42345651793831]
	var expected_result =  [[[-91.91208030440808, 42.29356419217009],
		[-91.93359375, 42.32606244456202], [-91.7578125, 42.3228109416169]]]
	

	var result = line_clip.line_clip(line, bbox)	
	
	assert_eq(result, expected_result)	
	
# Test preserves line if no protrusions exist
func test_line_preservation():
	var points = [[1, 1], [2, 2], [3, 3]]
	var bbox = [0, 0, 30, 30]
	var expected_result = [[[1, 1], [2, 2], [3, 3]]]
	
	var result = line_clip.line_clip(points, bbox)	
	
	assert_eq(result, expected_result)		

# Test clips without leaving empty parts
func test_mon_empty_clips():
	var points = [[40, 40], [50, 50]]
	var bbox = [0, 0, 30, 30]
	var expected_result = []
	
	var result = line_clip.line_clip(points, bbox)	
	
	assert_eq(result, expected_result)	

# Test still works when polygon never crosses bbox
func test_polygon_crosses_bbox():
	var points = [[3, 3], [5, 3], [5, 5], [3, 5], [3, 3]]
	var bbox = [0, 0, 2, 2]
	var expected_result = []
	
	var result = line_clip.line_clip(points, bbox)	
	
	assert_eq(result, expected_result)	
