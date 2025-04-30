extends Node

@export var tile_width: int = 200
@export var tile_height: int = 200

@export var moisture = FastNoiseLite.new()
@export var temperature = FastNoiseLite.new()
@export var altitude = FastNoiseLite.new()
@export var tree_noise = FastNoiseLite.new()
@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var environment_layer: TileMapLayer = $EnvironmentLayer

@onready var player: CharacterBody2D = $Player

var forest_id = 0
var desert_id = 1
var tundra_id = 2
var water_id = 3

var base_water_atlas = Vector2i(4, 7)
var base_land_atlas = Vector2i(2, 6)
var tree_objects = {
	"forest": [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(6, 1)],
	"desert": [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)],
	"tundra": [Vector2i(1, 1), Vector2i(2, 1)]
}


func _ready() -> void:
	generate_world()
	
func generate_world() -> void:
	moisture.seed = randi() #should hard code for debugging
	temperature.seed = randi()
	altitude.seed = randi()
	tree_noise.seed = randi()
	tree_noise.frequency = 0.35
	tree_noise.fractal_octaves = 4
	
	generate_chunk(player.position)

#func _process(delta: float) -> void:
	#generate_chunk(player.position)
	
func generate_chunk(position):
	var tile_pos = ground_layer.local_to_map(position)
	
	# Initialize biome lists
	var chunk_tiles = {
		"water": [],
		"forest": [],
		"desert": [],
		"tundra": []
	}
	var environment_tiles = []

	for x in range(tile_width):
		for y in range(tile_height):
			var x_chunk = tile_pos.x - tile_width / 2 + x
			var y_chunk = tile_pos.y - tile_height / 2 + y
			var chunk_vector = Vector2i(x_chunk, y_chunk)

			# Get noise values
			var altitude_noise = altitude.get_noise_2d(x_chunk, y_chunk)
			var moisture_noise = moisture.get_noise_2d(x_chunk, y_chunk)
			var temperature_noise = temperature.get_noise_2d(x_chunk, y_chunk)
			var tree_noise_value = tree_noise.get_noise_2d(x_chunk, y_chunk)

			# Determine biome
			var biome = classify_biome(altitude_noise, moisture_noise, temperature_noise)
			chunk_tiles[biome].append(chunk_vector)
			
			# Add biome-specific environment objects now
			var object_tile = get_environment_object(biome, tree_noise_value)
			if object_tile != null:
				environment_tiles.append({"pos": chunk_vector, "tile": object_tile})

	# Apply biomes to terrain layer
	ground_layer.set_cells_terrain_connect(chunk_tiles["water"], 0, water_id)
	ground_layer.set_cells_terrain_connect(chunk_tiles["forest"], 0, forest_id)
	ground_layer.set_cells_terrain_connect(chunk_tiles["desert"], 0, desert_id)
	ground_layer.set_cells_terrain_connect(chunk_tiles["tundra"], 0, tundra_id)
	
	# Apply environment objects
	for tile in environment_tiles:
		environment_layer.set_cell(tile["pos"], 0, tile["tile"])


func classify_biome(altitude: float, moisture: float, temperature: float) -> String:
	if altitude < 0.1:
		return "water"
	elif altitude < 0.8:
		if temperature < 0.4 and abs(moisture) < 0.9:
			return "forest"
		elif temperature > 0.4 and moisture < 0.5:
			return "desert"
	return "tundra"  # Default case

func get_environment_object(biome: String, noise_value: float):
	if biome == "water":
		return null #no water objects
	if noise_value > 0.5: #threshold for object spawning
		var object_list = tree_objects.get(biome, [])
		if object_list.size() > 0:
			return object_list[randi() % object_list.size()] # picks a random object from the list
	return null #no object if below noise threshold
