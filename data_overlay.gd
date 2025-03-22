extends Node2D

var _voronoi: Voronoi
var _grid: Grid

func _ready():
	print ("Ready entered")


func test(voronoi: Voronoi, grid:Grid):
	print ("test entered")
	print ("Size of grid is: ", grid.width)
	_grid = grid
	_voronoi = voronoi
	pass
	
	
func _draw()  -> void:
	
	#var voronoi_cell_dict: Dictionary = _voronoi.get_voronoi_cells()	
	#var font : Font
	#font = ThemeDB.fallback_font
	#
	#for p in _grid.points_n:
#
		#var temperature = _grid.cells["temp"][p]
#
		## Add the temperature value as text
		#var voronoi_vertice = []
		#voronoi_vertice.append([])
#
		#for vertice in voronoi_cell_dict[p]:
			#voronoi_vertice[0].append(Vector2(vertice[0], vertice[1]))
		## get the polylabel position
		#var polylabel = PolyLabel.new()
		#var result = polylabel.get_polylabel(voronoi_vertice, 1.0, false)
		## set up to print out the temperature value
		#draw_string(font, Vector2(result[0], result[1]), str(temperature), 0, -1, 8, Color.BLACK)
		pass
