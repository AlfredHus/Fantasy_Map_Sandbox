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
	voronoi_cell_elevation.resize(voronoi.voronoi_cell_sites.size())
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
		voronoi_cell_elevation[key] = average_elevation
		
		
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
	
	return color	# https://www.arcgis.com/home/item.html?id=e11ebaeb19544bb18c2afe440f063062	
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
	
