# Handles the elevation for the maq
class_name Elevation
extends Node2D

# YThis will contain the elevation for each of the voronoi cells, the cell site.
var voronoi_cell_elevation:  PackedFloat32Array = []
# This will contain the elevation for each of the vertices on the voronou polygon
var voronoi_vertex_elevation:  PackedFloat32Array = []
var voronoi_vertex_elevation_remapped:  PackedInt32Array = []

var voronoi: Voronoi

var elevation_noise = FastNoiseLite.new()

# source: https://github.com/Maiqtheterrorist/godot-landmass-generator/blob/main/LandmassGeneration/scripts/generationScripts/landmasGenerationScript.gd
var fastNoiseLite : FastNoiseLite = FastNoiseLite.new()
var combinedImages : Image 
var finalTexture
var textures : Dictionary = {}
var images = {}

func _init(voronoi: Voronoi) -> void:
	#voronoi_cell_elevation.resize(voronoi.voronoi_cell_sites.size())
	voronoi_cell_elevation.resize(voronoi.voronoi_cell_dict.size())
	voronoi_vertex_elevation.resize(voronoi.voronoi_vertices.size())
	voronoi_vertex_elevation_remapped.resize(voronoi.voronoi_vertices.size())
	self.voronoi = voronoi

# Generates the elevation
# TODO. Right now, the values for FastNoiseLite are hardcoded. Consider 
# adding these as either function parameters or part of the UI
func generate_elevation(elevation_seed: int) -> void:
 	# Set the seed
	elevation_noise.seed = elevation_seed
	# Set noise parameters
	#elevation_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	elevation_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	# The lower the frequency is, the wider the terrain features
	#elevation_noise.frequency = 0.3
	elevation_noise.fractal_lacunarity = 1.9 # 2.0
	#elevation_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	# The more octaves, the less smoothly separated the terrain features will be
	elevation_noise.fractal_octaves = 5 # 6
	
	#elevation_noise.frequency = 0.003 / (float(voronoi_cell_elevation.size()) / 512.0)
	#elevation_noise.frequency = 0.003 / (512.0 / 512.0)
	elevation_noise.frequency = 0.004
	
	# assign noise values to the voronoi_elevation_vertices.
	for i: int in voronoi_vertex_elevation.size():
		voronoi_vertex_elevation[i] = elevation_noise.get_noise_2d(voronoi.voronoi_vertices[i].x, voronoi.voronoi_vertices[i].y)
		#var e = 1 * elevation_noise.get_noise_2d(voronoi.voronoi_vertices[i].x * 1, voronoi.voronoi_vertices[i].y * 1)
		#e += 0.5 * elevation_noise.get_noise_2d(voronoi.voronoi_vertices[i].x * 2, voronoi.voronoi_vertices[i].y * 2)
		#e += 0.25 * elevation_noise.get_noise_2d(voronoi.voronoi_vertices[i].x * 4, voronoi.voronoi_vertices[i].y * 4)	
		#e = e / (1 + 0.5 + 0.25)
		#voronoi_vertex_elevation[i] = pow(e, 1)
		voronoi_vertex_elevation_remapped[i] = remap_noise_to_grayscale(voronoi_vertex_elevation[i])
		
	for key in voronoi.voronoi_cell_dict:
		var temp_dict_size = voronoi.voronoi_cell_dict[key].size()
		var average_elevation: float = 0.0
		for i: int in voronoi.voronoi_cell_dict[key].size():
			var temp_vertices = voronoi.voronoi_vertices[key]
			var temp_cell_vertices = voronoi.voronoi_cell_dict[key]
			var  temp_cell = Vector2(temp_cell_vertices[i].x, temp_cell_vertices[i].y)
			#print ("Looking for voronoi.voronoi_cell_dict value", temp_cell, " in key :", key)
			var search_result = voronoi.voronoi_vertices.find(temp_cell) 
			if search_result != -1:
				#print ("Found voronoi.voronoi_cell_dict value: ", temp_cell , "in ", search_result)
				# Assign elevation to the voronoi cell sites. We take the average of the
				# vornoi cell vertices and assign that to the site.		
				average_elevation += voronoi_vertex_elevation[search_result]
		average_elevation /= voronoi.voronoi_cell_dict[key].size()
		#voronoi_cell_elevation[key] = average_elevation # FIXME Change array to dictionary or change to something else
		
		
func generate_elevation_from_image() -> void:
 
	# assign noise values to the voronoi_elevation_vertices.
	#for i: int in voronoi_vertex_elevation.size():
		#voronoi_vertex_elevation[i] = elevation_noise.get_noise_2d(voronoi.voronoi_vertices[i].x, voronoi.voronoi_vertices[i].y)
		#var e = 1 * elevation_noise.get_noise_2d(voronoi.voronoi_vertices[i].x * 1, voronoi.voronoi_vertices[i].y * 1)
		#e += 0.5 * elevation_noise.get_noise_2d(voronoi.voronoi_vertices[i].x * 2, voronoi.voronoi_vertices[i].y * 2)
		#e += 0.25 * elevation_noise.get_noise_2d(voronoi.voronoi_vertices[i].x * 4, voronoi.voronoi_vertices[i].y * 4)	
		#e = e / (1 + 0.5 + 0.25)
		#voronoi_vertex_elevation[i] = pow(e, 1)
		#voronoi_vertex_elevation_remapped[i] = remap_noise_to_grayscale(voronoi_vertex_elevation[i])
		
		voronoi_cell_elevation = load_grayscale_image("E:/Godot Projects/My Projects/polygon-island-generation/europe1.png")
		pass
		
func remap_noise_to_grayscale(value: float) -> float:
	# Clamp the input to the -1 to 1 range to avoid out-of-bound values
	value = clamp(value, -1.0, 1.0)
	# Remap the value from the range -1 to 1 to the range 0 to 255
	return lerp(0, 255, (value + 1) / 2.0)
	
	
func remap_grayscale_to_noise(value: float) -> float:
	# Clamp the input to the 0 to 255 range to avoid out-of-bound values
	value = clamp(value, 0, 255)
	# Remap the value from the range 0 to 255 to the range -1 to 1 by 
	# first converting the value to 0 to 1 (value / 255.0) and then converting
	# the 0 to 1 to the range -1 to 1
	return (value / 255.0) * 2.0 - 1.0
	
func load_grayscale_image(path: String) -> Array:
	# Load the image from the specified path
	var img = Image.new()
	if img.load(path) != OK:
		push_error("Failed to load image at: " + path)
		return []
	
	# Convert the image to grayscale if not already
	img.convert(Image.FORMAT_L8)  # FORMAT_L8 ensures it's a single-channel grayscale image
	
	# resize image
	img.resize(67,67)

	# Initialize an array to store the normalized values
	var normalized_values: Array[float]
	var row: Array[float]
	var count = 0
	# Loop through each pixel in the image
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			# Get the grayscale value (0-255) at the current pixel
			var grayscale_value = img.get_pixel(x, y).r * 255.0  # The red channel holds the grayscale value
			
			# Normalize the grayscale value to the range -1 to 1
			var normalized_value = (grayscale_value / 255.0) * 2.0 - 1.0
			count += 1
			# Store the normalized value
			row.append(normalized_value)
		#normalized_values.append(row)
	

	
	#return normalized_values  # Returns a 2D array of normalized values
	print ("Size of resized image = ", row.size(), "count = ", count)
	return row



func assign_basic_colors(elevation_value: float) -> Color:
	var color: Color
	if elevation_value < -0.5:  # > 8000
		color =  Color.BLUE
	elif elevation_value < 0: 
		color = Color.DARK_CYAN
	elif elevation_value < 0.35:
		color = Color.GREEN
	elif elevation_value < 0.8:
		color = Color.GRAY
	elif elevation_value < 1.0:
		color = Color.WHITE
	return color
	
func elevation_color(elevation_value: float) -> Color:
	var color: Color
	if elevation_value > .8:  # > 8000
		color =  Color(0.92157, 0.91765, 0.96863)
	elif (elevation_value > .7 and elevation_value <= .8): # 4000 - 8000
		color =  Color (0.87059, 0.870594, 0.81176)
	elif (elevation_value > .6 and elevation_value <= .7): # 2000 = 4000
		color =  Color (0.87, 0.84, 0.8)
	elif (elevation_value > .5 and elevation_value <= .6): # 1000 - 2000
		color =  Color (0.8, 0.72, 0.6)
	elif (elevation_value > .4 and elevation_value <= .5): # 500 - 1000
		color =  Color (0.73, 0.58, 0.4)		
	elif (elevation_value > .3 and elevation_value <= .4): # 250 - 500
		color =  Color (0.59, 0.49, 0.25)	
	elif (elevation_value > .2 and elevation_value <= .3): # 50 - 250
		color =  Color (0.46, 0.46, 0.18)	
	elif (elevation_value > .1 and elevation_value <= .2): # 10 - 50
		color =  Color (0.27, 0.42, 0.09)	
	elif (elevation_value > 0 and elevation_value <= .1): # 0 - 10
		color =  Color (0.00392, 0.25490, 0.14510)	
	#elif (elevation_value < 0 and elevation_value <= -.1): # 0  to -2
	elif (elevation_value < 0 and elevation_value >= -.1): # 0  to -2
		color =  Color (0.90588, 0.90588, 0.91765)	
	elif (elevation_value < -.1 and elevation_value >= -.2): # -2 to 10 
		color =  Color (0.47, 0.77, 0.8)
	elif (elevation_value < -.2 and elevation_value >= -.3): # -10 to -50
		color =  Color (0.36, 0.67, 0.79)	
	elif (elevation_value < -.3 and elevation_value >= -.4): # -50 to -250
		color =  Color (0.25, 0.58, 0.79)
	elif (elevation_value < -.4 and elevation_value >= -.5): # -250 to -1000
		color =  Color (0.18, 0.46, 0.69)
	elif (elevation_value < -.5 and elevation_value >=-.6): # -1000 to -2000
		color =  Color (0.14, 0.34, 0.53)
	elif (elevation_value < -.6 and elevation_value >=-.7): # -2000 to -4000
		color =  Color (0.12, 0.25, 0.33)	
	elif (elevation_value < -.7 and elevation_value >= -.8): # 4000 to -8000
		color =  Color (0.11, 0.23, 0.27)
	elif (elevation_value < -.8 and elevation_value >= -1.0): # >8000
		color =  Color (0.1, 0.2, 0.22)	
	else: color = Color(1,0,0)
	return color
	
	
func elevation_color_v1(elevation_value: float) -> Color:
	var color: Color
	if elevation_value > .8:  # > 8000
		color =  Color(0.92157, 0.91765, 0.96863)
	elif (elevation_value > .7): # 4000 - 8000
		color =  Color (0.87059, 0.870594, 0.81176)
	elif (elevation_value > .6): # 2000 = 4000
		color =  Color (0.87, 0.84, 0.8)
	elif (elevation_value > .5): # 1000 - 2000
		color =  Color (0.8, 0.72, 0.6)
	elif (elevation_value > .4): # 500 - 1000
		color =  Color (0.73, 0.58, 0.4)		
	elif (elevation_value > .3): # 250 - 500
		color =  Color (0.59, 0.49, 0.25)	
	elif (elevation_value > .2): # 50 - 250
		color =  Color (0.46, 0.46, 0.18)	
	elif (elevation_value > .1): # 10 - 50
		color =  Color (0.27, 0.42, 0.09)	
	elif (elevation_value > 0): # 0 - 10
		color =  Color (0.00392, 0.25490, 0.14510)	
	#elif (elevation_value < 0 and elevation_value <= -.1): # 0  to -2
	elif (elevation_value < -.8): # >8000
		color =  Color (0.1, 0.2, 0.22)	
	elif (elevation_value < -.7): # 4000 to -8000
		color =  Color (0.11, 0.23, 0.27)	
	elif (elevation_value < -.6): # -2000 to -4000
		color =  Color (0.12, 0.25, 0.33)	
	elif (elevation_value < -.5): # -1000 to -2000
		color =  Color (0.14, 0.34, 0.53)		
	elif (elevation_value < -.4): # -250 to -1000
		color =  Color (0.18, 0.46, 0.69)
	elif (elevation_value < -.3): # -50 to -250
		color =  Color (0.25, 0.58, 0.79)		
	elif (elevation_value < -.2): # -10 to -50
		color =  Color (0.36, 0.67, 0.79)			
	elif (elevation_value < -.1): # -2 to 10 
		color =  Color (0.47, 0.77, 0.8)							
	elif (elevation_value < 0): # 0  to -2
		#color =  Color (0.90588, 0.90588, 0.91765)	
		color =  Color (0.87, 0.98, 0.89)	
	else: color = Color(1,0,0)
	
	return color	
	
	# https://www.arcgis.com/home/item.html?id=e11ebaeb19544bb18c2afe440f063062	
func elevation_color_v2(elevation_value: float) -> Color:
	var color: Color
	if elevation_value > .95:  # > 8000
		color =  Color(0.92157, 0.91765, 0.96863)
	elif (elevation_value > .88): # 4000 - 8000
		color =  Color (0.87059, 0.870594, 0.81176)
	elif (elevation_value > .76): # 2000 = 4000
		color =  Color (0.87, 0.84, 0.8)
	elif (elevation_value > .64): # 1000 - 2000
		color =  Color (0.8, 0.72, 0.6)
	elif (elevation_value > .52): # 500 - 1000
		color =  Color (0.73, 0.58, 0.4)		
	elif (elevation_value > .40): # 250 - 500
		color =  Color (0.59, 0.49, 0.25)	
	elif (elevation_value > .28): # 50 - 250
		color =  Color (0.46, 0.46, 0.18)	
	elif (elevation_value > .16): # 10 - 50
		color =  Color (0.27, 0.42, 0.09)	
	elif (elevation_value > 0): # 0 - 10
		color =  Color (0.00392, 0.25490, 0.14510)	
	elif (elevation_value < -.95): # >8000
		color =  Color (0.1, 0.2, 0.22)	
	elif (elevation_value < -.92): # 4000 to -8000
		color =  Color (0.11, 0.23, 0.27)	
	elif (elevation_value < -.80): # -2000 to -4000
		color =  Color (0.12, 0.25, 0.33)	
	elif (elevation_value < -.68): # -1000 to -2000
		color =  Color (0.14, 0.34, 0.53)		
	elif (elevation_value < -.56): # -250 to -1000
		color =  Color (0.18, 0.46, 0.69)
	elif (elevation_value < -.44): # -50 to -250
		color =  Color (0.25, 0.58, 0.79)		
	elif (elevation_value < -.32): # -10 to -50
		color =  Color (0.36, 0.67, 0.79)			
	elif (elevation_value < -.20): # -2 to 10 
		color =  Color (0.47, 0.77, 0.8)							
	elif (elevation_value < 0): # 0  to -2
		#color =  Color (0.90588, 0.90588, 0.91765)	
		color =  Color (0.87, 0.98, 0.89)	
	else: color = Color(1,0,0)
	
	return color	

func elevation_color_v3(elevation_value: int) -> Color:
	var color: Color
	if elevation_value > 90:  # Mountains
		color =  Color.BROWN
	elif (elevation_value > 80): # Hills
		color =  Color.SADDLE_BROWN
	elif (elevation_value > 70): #
		color =  Color.SANDY_BROWN
	elif (elevation_value > 60): # 1000 - 2000
		color =  Color.YELLOW
	elif (elevation_value > 50): # 500 - 1000
		color =  Color.LIGHT_YELLOW		
	elif (elevation_value > 40): # 250 - 500
		color =  Color.DARK_GREEN	
	elif (elevation_value > 30): # 50 - 250
		color =  Color.GREEN
	elif (elevation_value > 20): # 10 - 50
		color =  Color.LIGHT_GREEN
	elif (elevation_value > 10): # 0 - 10
		color =  Color.LIGHT_BLUE	
	elif (elevation_value > 0): # >8000
		color =  Color.NAVY_BLUE
	elif (elevation_value == 0): # 4000 to -8000
		color =  Color.DARK_BLUE
	else: color = Color(1,0,0)
	
	return color	

# http://seaviewsensing.com/pub/cpt-city/wkp/shadowxfox/index.html
func elevation_color_cpt_city_columbia(elevation_value: int) -> Color:
	if elevation_value == 0: return Color (0.0000,0.1176,0.3137)  # Blue
	if elevation_value < 11: return Color (0.0000,0.2000,0.4000)  # Blue
	if elevation_value < 22: return Color (0.0000,0.4000,0.6000)  # Blue
	if elevation_value < 33: return Color (0.0000,0.6000,0.8039)  # Blue
	if elevation_value < 38: return Color (0.3922,0.7843,1.0000)  # Blue
	if elevation_value < 42: return Color (0.7765,0.9255,1.0000)  # Blue
	if elevation_value < 44: return Color (0.5804,0.6706,0.5176)  # Green
	if elevation_value < 45: return Color (0.6745,0.7490,0.5451)
	if elevation_value < 46: return Color (0.7412,0.8000,0.5882)
	if elevation_value < 50: return Color (0.8941,0.8745,0.6863)
	if elevation_value < 55: return Color (0.9020,0.7922,0.5804)
	if elevation_value < 66: return Color (0.8039,0.6706,0.5137)
	if elevation_value < 77: return Color (0.8039,0.6706,0.5137)
	if elevation_value < 88: return Color (0.7098,0.5961,0.5020)
	if elevation_value <= 100: return Color (0.6078,0.4824,0.3843)
	return Color.RED

func elevation_color_cpt_city_topo_15lev(elevation_value: int) -> Color:
	#if elevation_value == 0: return Color (0.1569,0.2118,0.6039)  # Blue
	if elevation_value < 4: return Color.DARK_BLUE # Blue
	if elevation_value < 7: return Color.BLUE # Blue
	if elevation_value < 10: return Color.SKY_BLUE # Blue
	#if elevation_value < 6: return Color (0.0000,0.7882,0.1961)   # Green
	#if elevation_value < 12: return Color (0.1176,0.8275,0.4078)  # Green
	if elevation_value < 18: return Color (0.3686,0.8784,0.4549)
	if elevation_value < 25: return Color (0.6353,0.9216,0.5098)
	if elevation_value < 31: return Color (0.8745,0.9725,0.5725)
	if elevation_value < 37: return Color (0.9647,0.8980,0.5843)
	if elevation_value < 43: return Color (0.7843,0.6980,0.4627)
	if elevation_value < 50: return Color (0.6353,0.4941,0.3686)
	if elevation_value < 56: return Color (0.5608,0.3804,0.3294)
	if elevation_value < 62: return Color (0.6353,0.4902,0.4549)
	if elevation_value < 68: return Color (0.6980,0.5882,0.5451)
	if elevation_value < 75: return Color (0.7804,0.6902,0.6667)
	if elevation_value < 81: return Color (0.8588,0.8039,0.7922)
	if elevation_value < 87: return Color (0.9255,0.8941,0.8863)
	if elevation_value < 93: return Color (1.0000,1.0000,1.0000)
	if elevation_value <= 100: return Color (1.0000,1.0000,1.0000)
	return Color.RED

# Land is greater than 20 which is the default set by Azgaars code
# so for now we will just used that value.
func elevation_color_azgaar_colors(elevation_value: int) -> Color:
	#if elevation_value == 0: return Color (0.1569,0.2118,0.6039)  # Blue
	
	# First color is a Dark Blue, then following colors are Blue
	# from darkest to lightest
	if elevation_value < 6: return Color (0.42,0.55,0.74) 
	if elevation_value < 8: return Color (0.47,0.64,0.79) # Blue
	if elevation_value < 10: return Color (0.54,0.69,0.83) # Blue
	if elevation_value < 20: return Color (0.6, .69, .83)  # Blue
	if elevation_value < 23: return Color (0.3686,0.8784,0.4549) # Green
	if elevation_value < 26: return Color (0.6353,0.9216,0.5098) # Green
	if elevation_value < 31: return Color (0.8745,0.9725,0.5725) # Green
	if elevation_value < 37: return Color (0.9647,0.8980,0.5843) # Yellow
	if elevation_value < 43: return Color (0.7843,0.6980,0.4627) # Yellow Brown
	if elevation_value < 50: return Color (0.6353,0.4941,0.3686) # Brown
	if elevation_value < 56: return Color (0.5608,0.3804,0.3294)
	if elevation_value < 62: return Color (0.6353,0.4902,0.4549)
	if elevation_value < 68: return Color (0.6980,0.5882,0.5451) # Brown
	if elevation_value < 75: return Color (0.7804,0.6902,0.6667) # Reddish brown
	if elevation_value < 81: return Color (0.8588,0.8039,0.7922) # Brown
	if elevation_value < 87: return Color (0.9255,0.8941,0.8863) # Light Grey
	if elevation_value < 93: return Color (1.0000,1.0000,1.0000)
	if elevation_value <= 100: return Color (1.0000,1.0000,1.0000)
	return Color.RED
	
	
func elevation_color_azgaar_colors_bw(elevation_value: int) -> Color:
	if elevation_value == 0: return Color.BLACK
	if elevation_value < 99: return Color.BLUE
	if elevation_value == 100: return Color.WHITE
	return Color.RED
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _draw():
	pass
	




func _fastNoiseLite_initializer() -> void:
	fastNoiseLite.noise_type = FastNoiseLite.TYPE_PERLIN
	fastNoiseLite.fractal_type = FastNoiseLite.FRACTAL_NONE

func _generate_noise_map(width : int, height : int, scale : float, octaves : int, persistance : float, lacunarity : float) -> ImageTexture:
	combinedImages = Image.create(width,height,false,Image.FORMAT_RGBA8)
	var usableFrequency = lacunarity
	var usableAmplitude = persistance
	
	for i in octaves:
		var noiseImage : Image = Image.create(width,height,false,Image.FORMAT_RGBA8)
		usableFrequency = pow(lacunarity, i)
		usableAmplitude = pow(persistance, i)
		prints(usableAmplitude,usableFrequency)
		
		for y in height:
			for x in width:
				var sampleY = y/scale * usableFrequency
				var sampleX = x/scale * usableFrequency
				
				var combinedImagePixel = combinedImages.get_pixel(x, y)
				var fnlPixel = Color.from_hsv(0.0,0.0,(fastNoiseLite.get_noise_2d(sampleX,sampleY)+1)/2)*usableAmplitude
				combinedImagePixel = (combinedImagePixel+fnlPixel*usableAmplitude)
				combinedImages.set_pixel(x,y, combinedImagePixel)
				
				noiseImage.set_pixel(x,y, Color.from_hsv(0.0, 0.0, (fastNoiseLite.get_noise_2d(sampleX,sampleY)+1)/2)*usableAmplitude)
				
			images.merge({"image " + str(i) : noiseImage})
		
		var noiseTextureInstance : ImageTexture = ImageTexture.create_from_image(noiseImage)
		textures.merge({"image " + str(i) : noiseTextureInstance})
	finalTexture = ImageTexture.create_from_image(combinedImages)
	
	return finalTexture	
	
