class_name Pack
extends Node
## The pack class holds the Azgaar pack object data.
## https://github.com/Azgaar/Fantasy-Map-Generator/wiki/Data-model#pack-object-1

# cells data, including voronoi data:
var cells: Dictionary = {
# Voronoi data
# cell indexes
	"i": [], # integer[]
# cells coordinates [x,y] after repacking. Numbers rounded to 2 decimals
	"p": [], # float[][]
# indexes of cell vertices
	"v": [],  # integer[][]
# indexes of cells adjacent to each cell (neighboring cells)
	"c": [],  # integer[][]
# indicates if cell borders map edge, 1 = true, 0 = false
	"b": [],  # integer[]
# indexes of source cell in grid. The only way to find correct grid parent for 
# pack cells
	"g": [], # integer[]
# specific cells data
# cells elevation in [0, 100] range, where 20 is the minimal land elevation
	"h": [],
# indexes of feature
	"f": [],
#  distance field. 1, 2, ... - land cells, -1, -2, ... - water cells, 0 - unmarked cell. 
	"t": [],
 # cells biome index
	"biome": [],
#  cells harbor score. Shows how many water cells are adjacent to the cell.
	"harbor": [],
# cells haven cells index. Each coastal cell has haven cells defined for correct routes building
	"haven": [],
	} 

# vertices data object, contains only voronoi data
var vertices: Dictionary = {
# vertex coordinates, [x,y]
	"p": [], # ingeger[][]
# neindexes of cells adjacent to each vertiex. Each vertex has 3 adjacent cells
	"v": [], # integer[][]
# indexes of vertices adjacent to each vertex. Most vertexes have 3 neighboring
# vertices, bordering vertices only have 2, while the third vertice is added 
# with a value of -1
	"c": []  # integer[][]  
	}

var points: PackedVector2Array 

# Contains dictionary of features -> islands, lakes and oceans. 
# Element 0 has no data. 
var features = []
# A feature that is stored in the features array
var feature: Dictionary = {
# i: integer - feature id starting from 1
# land: bool - true if feature is land (height >= 20)
# border: bool - true if feature touches map border (used to separate lakes 
# 			    from oceans)
# type: String - feature type can be "ocean", "island" or "lake"
# group: String - feature subtype, depends on type. Subtype for "ocean" is 
#                 "ocean"; for "land" it is "continent", "island", "isle" 
#                 or "lake_island". 
#                 For "lake" it is "freshwater", "salt", "dry", 
#                 "sinkhole" or "lava"
# cells: integer - number of cells in feature
# firstCell: integer: - index of the first (top left) cell in feature
# vertices: integer[] - indexes of vertices around the feature 
#                       (perimetric vertices)
# name: String - name, available for lake type only
}	
#
#func _init(cells_desired: int, area: Rect2):
	#self.cells_desired = cells_desired
	#_grid_area = area
	#width = area.size.x
	#height = area.size.y
	## snapped() is used to set the decimal places of the float value to 2
	##spacing = snappedf(sqrt((width * height) / cells_desired),0.01)
	#spacing = GeneralUtilities.rn(sqrt((width * height) / cells_desired),2)
	#cells_x = floor((width + 0.5 * spacing - 1e-10) / spacing)
	#cells_y = floor((height + 0.5 * spacing - 1e-10) / spacing)
