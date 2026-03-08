# Research Report: TileMap Workflow in Godot 4.x for 2D Top-Down RPGs

> **Date:** 2026-03-08
> **Engine:** Godot 4.3+ (GDScript)
> **Focus:** TileMap system, programmatic tile painting, AI-assisted workflow
> **Use Case:** 2D Top-Down Zelda-like RPG prototypes with Claude Code + Godot MCP

---

## Table of Contents

1. [TileMap System in Godot 4.x](#1-tilemap-system-in-godot-4x)
2. [Changes from Godot 3.x to 4.x](#2-changes-from-godot-3x-to-4x)
3. [Creating TileSets Programmatically](#3-creating-tilesets-programmatically)
4. [Painting Tiles via GDScript](#4-painting-tiles-via-gdscript)
5. [Terrain System (Autotiling)](#5-terrain-system-autotiling)
6. [Procedural Map Generation](#6-procedural-map-generation)
7. [Layer Architecture for 2D RPGs](#7-layer-architecture-for-2d-rpgs)
8. [Y-Sorting and Z-Ordering](#8-y-sorting-and-z-ordering)
9. [Collision and Navigation](#9-collision-and-navigation)
10. [External Map Editors](#10-external-map-editors)
11. [MCP Tools for TileMap Workflow](#11-mcp-tools-for-tilemap-workflow)
12. [Approach Comparison](#12-approach-comparison)
13. [Recommended Workflow for AI-Assisted Prototyping](#13-recommended-workflow-for-ai-assisted-prototyping)
14. [Free Resources](#14-free-resources)
15. [Sources](#15-sources)

---

## 1. TileMap System in Godot 4.x

### Core Architecture

The TileMap system in Godot 4.x is built around two primary components:

| Component | Type | Purpose |
|-----------|------|---------|
| **TileSet** | Resource (`.tres`) | Defines available tiles, their textures, physics, navigation, terrain rules |
| **TileMapLayer** | Node | Individual grid layer that references a TileSet and stores placed tile data |

A `TileSet` resource contains one or more **TileSetSource** objects (typically `TileSetAtlasSource`), which map regions of a texture atlas to individual tiles. Each tile is identified by three values:

| Field | Type | Description |
|-------|------|-------------|
| `source_id` | int16 | Identifies the TileSetSource within the TileSet |
| `atlas_coords` | Vector2i | Tile coordinates in the atlas (column, row) |
| `alternative_tile` | int16 | Variant (rotation/flip flags, or scene index) |

### TileSet Resource Structure

A TileSet defines:

- **Tile shape and layout:** Square, isometric, half-offset, or hexagon
- **Tile size:** e.g., `Vector2i(16, 16)` for 16x16 pixel tiles
- **Sources:** Integer-keyed map of TileSetSource references (atlas textures)
- **Property layers:** Physics, navigation, occlusion, and custom data layers
- **Terrain sets:** Groups of terrains with autotiling rules
- **Tile proxies:** Remapping table for redirecting tile references

### TileMapLayer Node

`TileMapLayer` is the primary node for placing tiles. It inherits from `Node2D` and stores tile data internally as a `HashMap<Vector2i, CellData>`.

Key properties:
- `tile_set: TileSet` — The shared TileSet resource
- `y_sort_enabled: bool` — Enable Y-based rendering order
- `rendering_quadrant_size: int` — Cells per rendering batch (default 16)
- `collision_enabled: bool` — Enable/disable physics collisions
- `navigation_enabled: bool` — Enable/disable navigation regions

Internally, cells are grouped into **RenderingQuadrant** objects (16x16 tile regions by default) to reduce draw call count. When `y_sort_enabled` is true, each tile gets its own logical quadrant keyed by its Y world coordinate, ensuring correct Y-sort ordering.

---

## 2. Changes from Godot 3.x to 4.x

### Major Breaking Changes

| Aspect | Godot 3.x | Godot 4.x |
|--------|-----------|-----------|
| **Primary node** | `TileMap` (single node, layers as property) | `TileMapLayer` (individual nodes per layer) |
| **TileMap status** | Active | **Deprecated** (no new features) |
| **Autotiling** | Bitmask-based autotile | Terrain system with peering bits |
| **Data format** | `PackedInt32Array` | `PackedByteArray` (binary, 12 bytes/cell) |
| **Layer management** | `tile_map.set_cell(layer, ...)` | `layer_node.set_cell(...)` |
| **set_cell() signature** | `set_cell(layer, coords, source_id, atlas_coords, alt)` | `set_cell(coords, source_id, atlas_coords, alt)` |

### Migration Path

In the Godot editor: select the TileMap node → open the TileMap bottom panel → click the toolbox icon → **"Extract TileMap layers as individual TileMapLayer nodes"**.

> **Important:** Always use `TileMapLayer` for new projects. The old `TileMap` node still works but is deprecated and will not receive new features.

### Binary Data Format

TileMapLayer stores tile data as binary in `.tscn` files:

```
Header: 2 bytes (uint16 LE format version)
Per cell: 12 bytes each
  - int16 LE: cell X
  - int16 LE: cell Y
  - uint16 LE: source_id
  - uint16 LE: atlas_coords.x
  - uint16 LE: atlas_coords.y
  - uint16 LE: alternative_tile
```

This binary format means tile data is **opaque** in `.tscn` files — you cannot easily read or edit it as text. This is a key reason why MCP tools that decode this format are valuable.

---

## 3. Creating TileSets Programmatically

### Creating a TileSet via GDScript

You can create a complete TileSet resource at runtime or via an `@tool` script:

```gdscript
## Cria um TileSet programaticamente a partir de uma imagem PNG
func create_tileset_from_image(texture_path: String, tile_size: Vector2i = Vector2i(16, 16)) -> TileSet:
    var tileset := TileSet.new()
    tileset.tile_size = tile_size

    # Criar fonte atlas
    var atlas_source := TileSetAtlasSource.new()
    atlas_source.texture = load(texture_path)  # ex: "res://assets/tilesets/overworld.png"
    atlas_source.texture_region_size = tile_size
    atlas_source.margins = Vector2i(0, 0)
    atlas_source.separation = Vector2i(0, 0)

    # CRÍTICO: definir a textura ANTES de chamar create_tile()
    # Caso contrário, ocorre erro "!room_for_tile"

    # Calcular quantos tiles cabem na textura
    var tex_size := atlas_source.texture.get_size()
    var cols := int(tex_size.x) / tile_size.x
    var rows := int(tex_size.y) / tile_size.y

    # Criar cada tile no atlas
    for row in rows:
        for col in cols:
            var atlas_coords := Vector2i(col, row)
            atlas_source.create_tile(atlas_coords)

    # Adicionar a fonte ao TileSet (source_id = 0)
    tileset.add_source(atlas_source)

    return tileset
```

### Adding Physics Layer

```gdscript
## Adiciona uma camada de física ao TileSet
func add_physics_to_tileset(tileset: TileSet) -> void:
    tileset.add_physics_layer()
    # Camada 0: colisão padrão
    tileset.set_physics_layer_collision_layer(0, 1)   # layer 1
    tileset.set_physics_layer_collision_mask(0, 1)     # mask 1
```

### Adding Navigation Layer

```gdscript
## Adiciona uma camada de navegação ao TileSet
func add_navigation_to_tileset(tileset: TileSet) -> void:
    tileset.add_navigation_layer()
    tileset.set_navigation_layer_layers(0, 1)  # navigation layer 1
```

### Adding Terrain Set

```gdscript
## Adiciona um terrain set para autotiling
func add_terrain_to_tileset(tileset: TileSet) -> void:
    tileset.add_terrain_set()
    tileset.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES)

    # Adicionar terrenos ao set
    tileset.add_terrain(0)  # terrain 0: grama
    tileset.set_terrain_name(0, 0, "Grass")
    tileset.set_terrain_color(0, 0, Color.GREEN)

    tileset.add_terrain(0)  # terrain 1: água
    tileset.set_terrain_name(0, 1, "Water")
    tileset.set_terrain_color(0, 1, Color.BLUE)
```

### Saving to .tres File

```gdscript
## Salvar o TileSet como recurso
func save_tileset(tileset: TileSet, path: String) -> void:
    var err := ResourceSaver.save(tileset, path)
    if err != OK:
        push_error("Falha ao salvar TileSet: %s" % error_string(err))
```

> **Practical note:** Creating TileSets programmatically is possible but tedious for setting up collision shapes and terrain peering bits per-tile. The recommended approach is to create the TileSet in the Godot editor (especially for collision/terrain configuration) and then paint the map programmatically.

---

## 4. Painting Tiles via GDScript

### Basic set_cell() Usage

```gdscript
## TileMapLayer.set_cell() - Godot 4.3+
## Signature:
##   set_cell(coords: Vector2i, source_id: int = -1,
##            atlas_coords: Vector2i = Vector2i(-1, -1),
##            alternative_tile: int = 0)

@onready var ground_layer: TileMapLayer = $GroundLayer

func _ready() -> void:
    # Colocar um tile de grama na posição (5, 3)
    ground_layer.set_cell(
        Vector2i(5, 3),    # posição no grid
        0,                  # source_id (primeira fonte do TileSet)
        Vector2i(0, 0)      # atlas_coords (primeiro tile do atlas)
    )

    # Apagar um tile (source_id = -1)
    ground_layer.set_cell(Vector2i(5, 3), -1)
```

### Fill a Rectangle

```gdscript
## Preencher uma região retangular com um tipo de tile
func fill_rect(layer: TileMapLayer, rect: Rect2i,
               source_id: int, atlas_coords: Vector2i) -> void:
    for x in range(rect.position.x, rect.end.x):
        for y in range(rect.position.y, rect.end.y):
            layer.set_cell(Vector2i(x, y), source_id, atlas_coords)

# Uso: preencher 20x15 tiles com grama
fill_rect($GroundLayer, Rect2i(0, 0, 20, 15), 0, Vector2i(0, 0))
```

### Other Useful Methods

```gdscript
## Obter todas as células usadas
var used_cells: Array[Vector2i] = ground_layer.get_used_cells()

## Obter os dados de uma célula
var source_id: int = ground_layer.get_cell_source_id(Vector2i(5, 3))
var atlas_coords: Vector2i = ground_layer.get_cell_atlas_coords(Vector2i(5, 3))
var tile_data: TileData = ground_layer.get_cell_tile_data(Vector2i(5, 3))

## Obter o retângulo usado
var bounds: Rect2i = ground_layer.get_used_rect()

## Limpar toda a camada
ground_layer.clear()

## Copiar/colar padrões
var pattern: TileMapPattern = ground_layer.get_pattern(cells_array)
ground_layer.set_pattern(Vector2i(10, 10), pattern)  # colar em outra posição
```

---

## 5. Terrain System (Autotiling)

### How Terrains Work

Godot 4's terrain system replaces the old autotile bitmask. It works via **peering bits** — each tile defines which terrain type it expects on each adjacent side and corner.

**Terrain Modes:**

| Mode | Peering Bits | Best For |
|------|-------------|----------|
| `MATCH_CORNERS_AND_SIDES` | 8 neighbors (3x3 grid) | RPG terrain (grass, water, paths) |
| `MATCH_SIDES` | 4 neighbors (sides only) | Simpler terrain, walls |
| `MATCH_CORNERS` | 4 neighbors (corners only) | Diagonal patterns |

### Setting Up Terrain in the Editor

1. In the TileSet inspector, expand **Terrain Sets** → Add element
2. Set the mode (usually `Match Corners and Sides`)
3. Add terrains (Grass, Water, Sand, etc.) with colors
4. In the TileSet editor, switch to **Paint** mode → **Terrains**
5. Paint peering bits on each tile in the 3x3 grid

### Painting Terrain Programmatically

```gdscript
## Pintar terrain com auto-conexão
## set_cells_terrain_connect(cells, terrain_set, terrain)
## - cells: Array de Vector2i com as posições
## - terrain_set: índice do terrain set (0, 1, ...)
## - terrain: índice do terrain dentro do set (0 = grama, 1 = água, ...)

func paint_grass_area(layer: TileMapLayer) -> void:
    var grass_cells: Array[Vector2i] = []
    for x in range(0, 20):
        for y in range(0, 15):
            grass_cells.append(Vector2i(x, y))

    # terrain_set 0, terrain 0 (grama)
    layer.set_cells_terrain_connect(grass_cells, 0, 0)

func paint_water_pond(layer: TileMapLayer) -> void:
    var water_cells: Array[Vector2i] = []
    for x in range(8, 12):
        for y in range(5, 8):
            water_cells.append(Vector2i(x, y))

    # terrain_set 0, terrain 1 (água)
    layer.set_cells_terrain_connect(water_cells, 0, 1)
```

**`set_cells_terrain_connect`** automatically selects the correct tile variant (edges, corners, inner tiles) based on which neighbors share the same terrain. You do NOT need to call `set_cell()` separately — the terrain method handles tile selection.

There is also `set_cells_terrain_path()` which handles path-like terrain painting (e.g., roads) where connectivity follows a path rather than filling an area.

> **Caveat:** The terrain API at runtime can be tricky. Some developers report that neighbor cells need to be included in the cells array for proper edge calculation. The community-made [Better Terrain](https://github.com/Portponky/better-terrain) plugin provides an alternative with a simpler API.

---

## 6. Procedural Map Generation

### Noise-Based Terrain (FastNoiseLite)

Godot 4 includes `FastNoiseLite` as a built-in class. Here's a complete example for generating a top-down RPG map:

```gdscript
extends Node2D

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var decoration_layer: TileMapLayer = $DecorationLayer

## Configurações do mapa
@export var map_width: int = 40
@export var map_height: int = 30
@export var noise_seed: int = 0  # 0 = aleatório

## Atlas coordinates para cada tipo de tile (ajustar conforme seu tileset)
const TILE_GRASS := Vector2i(0, 0)
const TILE_GRASS_DARK := Vector2i(1, 0)
const TILE_DIRT := Vector2i(2, 0)
const TILE_WATER := Vector2i(3, 0)
const TILE_SAND := Vector2i(4, 0)
const TILE_TREE := Vector2i(0, 1)
const TILE_ROCK := Vector2i(1, 1)

func _ready() -> void:
    generate_map()

func generate_map() -> void:
    # Configurar noise para terreno
    var terrain_noise := FastNoiseLite.new()
    terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    terrain_noise.seed = noise_seed if noise_seed != 0 else randi()
    terrain_noise.frequency = 0.05  # menor = terreno mais suave

    # Segundo noise para decorações (árvores, pedras)
    var decoration_noise := FastNoiseLite.new()
    decoration_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    decoration_noise.seed = terrain_noise.seed + 100
    decoration_noise.frequency = 0.1

    for x in map_width:
        for y in map_height:
            # Obter valor de noise normalizado (0 a 1)
            var terrain_value := remap(terrain_noise.get_noise_2d(x, y), -1.0, 1.0, 0.0, 1.0)
            var deco_value := remap(decoration_noise.get_noise_2d(x, y), -1.0, 1.0, 0.0, 1.0)

            # Mapear noise para tipo de terreno
            var tile := determine_terrain_tile(terrain_value)
            ground_layer.set_cell(Vector2i(x, y), 0, tile)

            # Adicionar decorações em tiles de grama
            if tile == TILE_GRASS or tile == TILE_GRASS_DARK:
                place_decoration(Vector2i(x, y), deco_value)

func determine_terrain_tile(noise_value: float) -> Vector2i:
    if noise_value < 0.25:
        return TILE_WATER
    elif noise_value < 0.35:
        return TILE_SAND
    elif noise_value < 0.65:
        return TILE_GRASS
    elif noise_value < 0.80:
        return TILE_GRASS_DARK
    else:
        return TILE_DIRT

func place_decoration(pos: Vector2i, noise_value: float) -> void:
    if noise_value > 0.75:
        decoration_layer.set_cell(pos, 0, TILE_TREE)
    elif noise_value > 0.70 and noise_value <= 0.75:
        decoration_layer.set_cell(pos, 0, TILE_ROCK)
```

### Ensuring Walkable Areas

```gdscript
## Garantir que a posição do jogador e arredores são caminháveis
func ensure_spawn_clear(spawn_pos: Vector2i, radius: int = 3) -> void:
    for x in range(spawn_pos.x - radius, spawn_pos.x + radius + 1):
        for y in range(spawn_pos.y - radius, spawn_pos.y + radius + 1):
            ground_layer.set_cell(Vector2i(x, y), 0, TILE_GRASS)
            decoration_layer.set_cell(Vector2i(x, y), -1)  # limpar decorações
```

### Performance Notes

- For maps larger than ~100x100, consider generating in chunks using `Thread`
- `set_cell()` is efficient for individual calls but bulk operations benefit from grouping
- Use `rendering_quadrant_size` tuning for large maps (default 16 is usually fine)

---

## 7. Layer Architecture for 2D RPGs

### Recommended Layer Structure

For a top-down RPG, use **3 to 5 TileMapLayer nodes** as siblings in the scene tree:

```
World (Node2D)
├── GroundLayer (TileMapLayer)     # z_index: 0  — grass, dirt, water, sand
├── PathLayer (TileMapLayer)       # z_index: 1  — roads, bridges, floor details
├── ObjectLayer (TileMapLayer)     # z_index: 2  — trees, rocks, walls (y_sort_enabled)
│   └── Player (CharacterBody2D)   # child for Y-sorting
│   └── Enemy (CharacterBody2D)    # child for Y-sorting
└── OverlayLayer (TileMapLayer)    # z_index: 3  — tree canopy, roof tops (always above player)
```

| Layer | Purpose | Physics | Navigation | Y-Sort |
|-------|---------|---------|------------|--------|
| **GroundLayer** | Base terrain (grass, dirt, water, sand) | Water collision only | Yes (walkable tiles) | No |
| **PathLayer** | Paths, bridges, floor decorations | No (or bridge collision) | Optional | No |
| **ObjectLayer** | Trees, rocks, walls, interactive objects | Yes (solid objects) | No | **Yes** |
| **OverlayLayer** | Tree tops, roofs, weather effects | No | No | No |

### Why This Structure?

- **GroundLayer** and **PathLayer** are flat — no Y-sorting needed
- **ObjectLayer** uses Y-sorting so the player can walk behind trees (player is a child of this layer)
- **OverlayLayer** always renders above everything (tree canopy, rain, etc.)
- All layers share the **same TileSet** resource — just different tiles painted on each

### Minimal Setup (For Quick Prototypes)

```
World (Node2D)
├── GroundLayer (TileMapLayer)     # grass, dirt, water
├── ObjectLayer (TileMapLayer)     # trees, rocks, walls (y_sort + collision)
│   └── Player
└── [Optional] OverlayLayer
```

Two layers is sufficient for a prototype. Add more as the game grows.

---

## 8. Y-Sorting and Z-Ordering

### Y-Sorting Setup

Y-sorting makes objects lower on the screen render in front of objects higher on the screen. This is critical for top-down RPGs where the player should appear behind trees when walking above them.

**Configuration steps:**

1. Enable `y_sort_enabled` on the TileMapLayer that contains objects (trees, rocks)
2. Make the Player and enemies **children** of that TileMapLayer
3. Ensure all objects that need sorting share the **same Z-index**

```
ObjectLayer (TileMapLayer, y_sort_enabled = true)
├── Player (CharacterBody2D)
├── Slime (CharacterBody2D)
```

### Per-Tile Y-Sort Origin

For tiles taller than one grid cell (e.g., a 16x32 tree on a 16x16 grid), you need to set the **y_sort_origin** in the TileSet editor:

- Select the tall tile in the TileSet editor
- In TileData, set `y_sort_origin` to the pixel offset where the "feet" of the tile are
- For a 16x32 tree, set `y_sort_origin = 16` (bottom of the tile)

This tells the engine: "sort this tile as if its Y position is at its feet, not its top."

### Z-Index for Non-Sorted Layers

For layers that should always render above or below:

```gdscript
$GroundLayer.z_index = 0      # sempre atrás
$ObjectLayer.z_index = 1      # Y-sorted com o player
$OverlayLayer.z_index = 10    # sempre na frente
```

> **Important:** Y-sorting only works correctly between objects with the same Z-index. If the player has `z_index = 0` and trees have `z_index = 1`, Y-sorting between them will NOT work.

---

## 9. Collision and Navigation

### Adding Collision to Tiles

1. In the TileSet inspector, add a **Physics Layer**
2. In the TileSet editor, switch to **Select** mode
3. Click on tiles that should be solid (trees, rocks, walls)
4. In the TileData panel, draw collision polygons

For a 16x16 tile, a full-tile collision is a rectangle covering the entire tile. For irregular shapes (tree trunk only), draw a smaller polygon.

### Adding Navigation to Tiles

1. In the TileSet inspector, add a **Navigation Layer**
2. In the TileSet editor, paint navigation regions on walkable tiles (grass, dirt, paths)
3. Any tile with a navigation polygon is considered **walkable**

### Using AStarGrid2D (Alternative to NavigationServer)

For simpler pathfinding, `AStarGrid2D` works well with tilemaps:

```gdscript
var astar := AStarGrid2D.new()

func setup_pathfinding() -> void:
    var bounds := ground_layer.get_used_rect()
    astar.region = bounds
    astar.cell_size = Vector2(16, 16)  # tile size
    astar.update()

    # Marcar tiles não-caminháveis como sólidos
    for cell in obstacle_layer.get_used_cells():
        astar.set_point_solid(cell, true)

func find_path(from: Vector2i, to: Vector2i) -> PackedVector2Array:
    return astar.get_point_path(from, to)
```

### NavigationAgent2D Setup

For more advanced pathfinding (enemies chasing the player):

```gdscript
## No script do inimigo
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var player: CharacterBody2D = %Player

func _ready() -> void:
    # Esperar um frame para o NavigationServer sincronizar
    await get_tree().physics_frame
    nav_agent.target_position = player.position

func _physics_process(delta: float) -> void:
    if nav_agent.is_navigation_finished():
        return

    var next_pos := nav_agent.get_next_path_position()
    var direction := (next_pos - global_position).normalized()
    velocity = direction * speed
    move_and_slide()
```

### Linking Navigation to Collision Tiles

By default, navigation and collision are separate. To exclude collision tiles from navigation at runtime:

```gdscript
## Script na GroundLayer para excluir tiles de obstáculo da navegação
extends TileMapLayer

@export var obstacle_layers: Array[TileMapLayer] = []

func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
    for layer in obstacle_layers:
        if layer.get_cell_source_id(coords) != -1:
            return true  # esta célula precisa de atualização
    return false

func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
    for layer in obstacle_layers:
        if layer.get_cell_source_id(coords) != -1:
            # Remover navegação onde há obstáculo
            tile_data.set_navigation_polygon(0, null)
```

---

## 10. External Map Editors

### Tiled Map Editor

[Tiled](https://www.mapeditor.org/) is the most popular external tilemap editor. It has **built-in Godot 4 export**.

**Export capabilities:**
- Exports `.tscn` scene files with TileMapLayer nodes
- Custom properties → Godot Custom Data Layers
- Tileset saved as external `.tres` for sharing between maps
- Supports `noExport` property to suppress layer export

**Godot 4 import options:**
- **Native Tiled export:** Built into Tiled 1.11+ (File → Export As → Godot 4)
- **YATI plugin:** [Yet Another Tiled Importer](https://github.com/Kiamo2/YATI) — supports all layer types, animations, collisions, custom data

**Pros:** Mature editor, large community, many tileset tools, autotile support
**Cons:** Separate tool, export/import workflow adds friction

### LDtk (Level Designer Toolkit)

[LDtk](https://ldtk.io/) is a modern, free level editor by the creator of Dead Cells.

**Godot integration:**
- [godot-ldtk-importer](https://github.com/heygleeson/godot-ldtk-importer) plugin
- Available in Godot AssetLib (search "LDtk")
- Supports: auto-reload on save, CanvasTextures, normal maps
- Preserves TileSet editor changes (physics layers, render layers)

**Pros:** Modern UI, excellent entity support, auto-reload on save
**Cons:** Less tilemap-specific tooling than Tiled, smaller community

### Sprite Fusion

[Sprite Fusion](https://www.spritefusion.com/) is a free browser-based tilemap editor.

**Features:**
- Web-based (no install needed)
- Auto-tiling support
- Direct Godot 3 and 4 export
- Collision support
- Free for personal and commercial use (4.5MB export limit on free version)

**Pros:** Zero setup, browser-based, auto-tiling
**Cons:** Limited features vs Tiled/LDtk, 4.5MB export limit on free tier

### Comparison

| Editor | Price | Godot 4 Export | Auto-tile | Entities | Real-time Reload |
|--------|-------|----------------|-----------|----------|-----------------|
| **Tiled** | Free (open source) | Built-in + plugins | Yes | Objects | No (re-import) |
| **LDtk** | Free (open source) | Plugin | Yes | Excellent | Yes |
| **Sprite Fusion** | Free web / $12 desktop | Built-in | Yes | No | No |

---

## 11. MCP Tools for TileMap Workflow

### godot-tilemap-mcp (Specialized)

[godot-tilemap-mcp](https://github.com/ekaitzsegurola/godot-tilemap-mcp) is an MCP server specifically designed for AI tilemap editing. It decodes the binary tile data in `.tscn` files and exposes 9 tools:

**Read-Only (5 tools):**

| Tool | Purpose |
|------|---------|
| `list_tilemaps` | Scan project for `.tscn` scenes with TileMapLayer nodes |
| `inspect_tileset` | Parse `.tres` TileSet files (sources, data layers, terrains, physics) |
| `get_tilemap_info` | Retrieve bounds, tile counts, tileset references, z-index, visibility |
| `read_tiles` | Decode tiles from a layer with optional region filtering |
| `render_tilemap` | Generate ASCII art visualization using source IDs or atlas coordinates |

**Write (4 tools):**

| Tool | Purpose |
|------|---------|
| `set_tiles` | Place or overwrite tiles at specific coordinates |
| `fill_rect` | Fill rectangular regions with a single tile type |
| `erase_tiles` | Remove tiles at specified positions |
| `erase_rect` | Clear all tiles in rectangular regions |

**Configuration:**
```json
{
  "mcpServers": {
    "godot-tilemap": {
      "command": "node",
      "args": ["/path/to/godot-tilemap-mcp/src/index.js"],
      "env": {
        "GODOT_PROJECT_PATH": "/path/to/your/godot/project"
      }
    }
  }
}
```

**Requirements:** Node.js 18+, Godot 4.x project with TileMapLayer nodes.

Path formats supported: absolute, relative (from `GODOT_PROJECT_PATH`), Godot-style (`res://`).

### Godot MCP Pro (General + TileMap)

[Godot MCP Pro](https://godot-mcp.abyo.net/) is a premium MCP server with 162 tools across 23 categories, including 6 TileMap-specific tools:

| Tool | Purpose |
|------|---------|
| `tilemap_set_cell` | Place individual tiles at specified coordinates |
| `tilemap_fill_rect` | Fill rectangular regions with tiles |
| `tilemap_get_cell` | Read tile data from specific positions |
| `tilemap_clear` | Remove all tiles from the map |
| `tilemap_get_info` | Access tile set sources and configuration |
| `tilemap_get_used_cells` | Query which cells contain tiles |

Additionally provides: scene manipulation, GDScript LSP, debugging, input simulation, animation, shader editing, audio management, and more.

**Connection:** WebSocket to Godot editor (requires editor running).

### Which MCP to Use?

| Use Case | Recommendation |
|----------|---------------|
| TileMap-only editing from Claude Code | **godot-tilemap-mcp** (free, specialized, works offline) |
| Full game development pipeline | **Godot MCP Pro** (paid, comprehensive, requires editor) |
| Quick prototyping without MCP | GDScript `set_cell()` in `@tool` scripts or `_ready()` |

---

## 12. Approach Comparison

### Approach A: Editor-Only (Manual)

Create TileSet and paint map entirely in the Godot editor.

| Pros | Cons |
|------|------|
| Visual feedback, WYSIWYG | Not automatable |
| Full terrain/collision tools | Tedious for large maps |
| No code needed | Can't integrate with AI workflow |
| Best for hand-crafted levels | Time-consuming iteration |

**Best for:** Final, polished levels; hand-crafted game areas.

### Approach B: Fully Programmatic

Generate both TileSet and TileMap entirely via GDScript.

| Pros | Cons |
|------|------|
| Fully automatable | Tedious collision/terrain setup |
| Reproducible (seed-based) | No visual preview during design |
| Good for procedural maps | Complex code for nice-looking results |
| AI can generate the code | Debugging visual issues is hard |

**Best for:** Roguelikes, procedural worlds, infinite maps.

### Approach C: Hybrid (Recommended)

Create TileSet manually in editor → Paint map programmatically or via MCP.

| Pros | Cons |
|------|------|
| Visual tileset design | Requires editor for TileSet setup |
| Programmatic map painting | Two-step workflow |
| AI can generate painting code | Need to know atlas coordinates |
| Best of both worlds | — |

**Best for:** AI-assisted prototyping, iterating on level layouts.

### Approach D: External Editor + Import

Design maps in Tiled/LDtk → Import into Godot.

| Pros | Cons |
|------|------|
| Mature map editing tools | External dependency |
| Auto-tiling, entity placement | Import/export friction |
| Platform-agnostic | Plugin maintenance risk |
| Good for large teams | Harder to integrate with AI |

**Best for:** Large projects, dedicated level designers, cross-engine workflows.

---

## 13. Recommended Workflow for AI-Assisted Prototyping

Given our setup (Claude Code + Godot MCP, 2D top-down RPG, 16x16 tiles), here is the recommended workflow:

### Phase 1: TileSet Setup (Manual in Godot Editor) — ~15 min

1. **Import tileset PNG** into `res://assets/tilesets/`
2. **Create TileSet resource** in the Godot editor:
   - Set tile size to 16x16
   - Add the PNG as an `AtlasSource`
   - Add **Physics Layer** (for collisions on trees, rocks, walls)
   - Add **Navigation Layer** (for pathfinding on walkable tiles)
   - Add **Terrain Set** with terrains (Grass, Water, Sand, Dirt) if autotiling is desired
3. **Configure tiles:**
   - Paint collision shapes on solid tiles (trees, rocks, walls)
   - Paint navigation polygons on walkable tiles (grass, dirt, path)
   - Paint terrain peering bits if using autotiling
4. **Save** the TileSet as `res://assets/tilesets/overworld.tres`

### Phase 2: Scene Structure (Manual or via MCP) — ~5 min

Create the map scene with TileMapLayer nodes:

```
MapScene.tscn
├── GroundLayer (TileMapLayer, tileset = overworld.tres)
├── ObjectLayer (TileMapLayer, tileset = overworld.tres, y_sort_enabled = true)
│   └── Player
└── OverlayLayer (TileMapLayer, tileset = overworld.tres, z_index = 10)
```

### Phase 3: Map Painting (AI-Assisted via Code or MCP)

**Option A — GDScript map generator:**

Claude Code writes a GDScript that paints tiles using `set_cell()` or `set_cells_terrain_connect()`. The script runs in `_ready()` or is an `@tool` script.

```gdscript
## map_generator.gd — Script gerador de mapa
## Anexar a um nó na cena ou rodar como @tool
@tool
extends Node2D

@export var regenerate: bool = false:
    set(value):
        if value:
            generate_map()
            regenerate = false

func generate_map() -> void:
    # Claude Code gera esta lógica baseado na descrição do mapa desejado
    var ground := $GroundLayer as TileMapLayer
    var objects := $ObjectLayer as TileMapLayer

    ground.clear()
    objects.clear()

    # Preencher chão com grama
    for x in range(0, 30):
        for y in range(0, 20):
            ground.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))  # grama

    # Adicionar árvores nas bordas
    for x in range(0, 30):
        objects.set_cell(Vector2i(x, 0), 0, Vector2i(0, 1))     # árvore
        objects.set_cell(Vector2i(x, 19), 0, Vector2i(0, 1))    # árvore
    for y in range(0, 20):
        objects.set_cell(Vector2i(0, y), 0, Vector2i(0, 1))     # árvore
        objects.set_cell(Vector2i(29, y), 0, Vector2i(0, 1))    # árvore
```

**Option B — godot-tilemap-mcp:**

If godot-tilemap-mcp is installed, Claude Code can directly paint tiles into `.tscn` files using MCP tools without running Godot:

```
1. list_tilemaps → find our MapScene.tscn
2. inspect_tileset → understand available tiles and atlas coords
3. fill_rect → fill ground with grass tiles
4. set_tiles → place trees, rocks at specific positions
5. render_tilemap → verify the result as ASCII art
```

**Option C — Procedural noise-based generation:**

Claude Code writes a noise-based generator (see Section 6) that creates varied, natural-looking terrain each time.

### Phase 4: Iterate

- Run the game, verify visually
- Adjust tile placement (ask Claude to modify the generator)
- Add collision/navigation if missing
- Refine until the map looks good

### Quick Reference: Atlas Coordinates

Create a reference document mapping tile names to atlas coordinates:

```
# Tileset Atlas Reference (overworld.png)
# source_id = 0
#
# Row 0 (terrain):
#   (0,0) = grass      (1,0) = grass_dark   (2,0) = dirt
#   (3,0) = water      (4,0) = sand
#
# Row 1 (objects):
#   (0,1) = tree        (1,1) = rock         (2,1) = bush
#   (3,1) = flower      (4,1) = stump
#
# Row 2 (structures):
#   (0,2) = wall_top    (1,2) = wall_mid     (2,2) = wall_bottom
#   (3,2) = door        (4,2) = chest
```

This reference lets Claude Code (or any AI) paint tiles by name without needing visual access to the tileset.

---

## 14. Free Resources

### Free Tilesets for Top-Down RPGs

| Resource | Tile Size | License | Link |
|----------|-----------|---------|------|
| 16x16 Pixel Forest Tileset | 16x16 | Free sample, CC | [OpenGameArt](https://opengameart.org/content/free-sample-16x16-pixel-forest-tileset-%E2%80%93-top-down-rpg-style) |
| 16-bit TopDown Zelda-Like | 16x16 | CC0 | [OpenGameArt](https://opengameart.org/content/16-bit-tileset-topdown-zelda-like-pro-version) |
| Interior Tileset 16x16 | 16x16 | CC | [OpenGameArt](https://opengameart.org/content/interior-tileset-16x16) |
| Pixel Crawler (dungeon) | 16x16 | Commercial license | Various |

### Free Tools

| Tool | Purpose | Link |
|------|---------|------|
| Tiled | External map editor (free, open source) | [mapeditor.org](https://www.mapeditor.org/) |
| LDtk | Modern level editor (free, open source) | [ldtk.io](https://ldtk.io/) |
| Sprite Fusion | Browser-based map editor | [spritefusion.com](https://www.spritefusion.com/) |
| YATI | Tiled → Godot importer plugin | [GitHub](https://github.com/Kiamo2/YATI) |
| godot-ldtk-importer | LDtk → Godot importer plugin | [GitHub](https://github.com/heygleeson/godot-ldtk-importer) |
| godot-tilemap-mcp | MCP server for AI tilemap editing | [GitHub](https://github.com/ekaitzsegurola/godot-tilemap-mcp) |
| Better Terrain | Improved terrain plugin for Godot 4 | [GitHub](https://github.com/Portponky/better-terrain) |

### Tutorials and Documentation

| Resource | Link |
|----------|------|
| Godot Docs: Using TileSets | [docs.godotengine.org](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html) |
| Godot Docs: Using TileMaps | [docs.godotengine.org](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilemaps.html) |
| GDQuest: TileSet Setup Cheatsheet | [gdquest.com](https://www.gdquest.com/library/cheatsheet_tileset_setup/) |
| GDQuest: TileMap Editor Basics | [gdquest.com](https://www.gdquest.com/library/cheatsheet_tilemap_basics/) |
| DeepWiki: TileMap System Architecture | [deepwiki.com](https://deepwiki.com/godotengine/godot/4.10-tilemap-system) |
| RPG TileMap Tutorial (DEV.to) | [dev.to](https://dev.to/christinec_dev/lets-learn-godot-4-by-making-an-rpg-part-4-game-tilemap-camera-setup-1mle) |
| Pathfinding Guide (casraf.dev) | [casraf.dev](https://casraf.dev/2024/09/pathfinding-guide-for-2d-top-view-tiles-in-godot-4-3/) |
| Procedural TileMaps (wayline.io) | [wayline.io](https://www.wayline.io/blog/godot-procedural-tilemaps) |
| Terrain Autotile Setup (uhiyama-lab) | [uhiyama-lab.com](https://uhiyama-lab.com/en/notes/godot/terrains-autotile-setup/) |
| Godot MCP Pro | [godot-mcp.abyo.net](https://godot-mcp.abyo.net/) |

---

## 15. Sources

- [Godot Docs: Using TileSets](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html)
- [Godot Docs: Using TileMaps](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilemaps.html)
- [Godot Docs: TileSet Class Reference](https://docs.godotengine.org/en/stable/classes/class_tileset.html)
- [Godot Docs: TileSetAtlasSource Class Reference](https://docs.godotengine.org/en/stable/classes/class_tilesetatlassource.html)
- [Godot Docs: TileMapLayer Class Reference](https://docs.godotengine.org/en/stable/classes/class_tilemaplayer.html)
- [Godot Docs: TSCN File Format](https://docs.godotengine.org/en/4.4/contributing/development/file_formats/tscn.html)
- [DeepWiki: TileMap System Architecture](https://deepwiki.com/godotengine/godot/4.10-tilemap-system)
- [GDQuest: TileSet Setup Cheatsheet](https://www.gdquest.com/library/cheatsheet_tileset_setup/)
- [GDQuest: TileMap Editor Basics](https://www.gdquest.com/library/cheatsheet_tilemap_basics/)
- [DEV.to: Learn Godot 4 RPG - TileMap Setup](https://dev.to/christinec_dev/lets-learn-godot-4-by-making-an-rpg-part-4-game-tilemap-camera-setup-1mle)
- [casraf.dev: Pathfinding Guide for 2D Tiles in Godot 4.3](https://casraf.dev/2024/09/pathfinding-guide-for-2d-top-view-tiles-in-godot-4-3/)
- [Wayline: Procedural TileMaps in Godot](https://www.wayline.io/blog/godot-procedural-tilemaps)
- [uhiyama-lab: Terrain Autotile Setup](https://uhiyama-lab.com/en/notes/godot/terrains-autotile-setup/)
- [Godot Forum: Create TileMap from Code](https://forum.godotengine.org/t/create-tilemap-from-code-in-godot-4/2972)
- [Godot Forum: TileMapLayer set_cell()](https://forum.godotengine.org/t/i-dont-understand-tilemaplayer-setcell/83976)
- [Godot Forum: Y-sort for TileMapLayer](https://forum.godotengine.org/t/how-to-make-y-sort-for-tilemaplayer-in-godot-4-3/87689)
- [Godot Forum: TileMap Binary Data Format](https://forum.godotengine.org/t/what-is-the-binary-data-format-of-a-tilemaplayer/134333)
- [GitHub: godot-tilemap-mcp](https://github.com/ekaitzsegurola/godot-tilemap-mcp)
- [GitHub: godot-ldtk-importer](https://github.com/heygleeson/godot-ldtk-importer)
- [GitHub: YATI (Tiled Importer)](https://github.com/Kiamo2/YATI)
- [GitHub: Better Terrain Plugin](https://github.com/Portponky/better-terrain)
- [GitHub: TileSetAtlasSource create_tile() Issue](https://github.com/godotengine/godot-docs/issues/10784)
- [Godot MCP Pro](https://godot-mcp.abyo.net/)
- [GameFromScratch: TileMap Replaced with TileMapLayers](https://gamefromscratch.com/godot-tilemap-replaced-with-tilelayers/)
- [Tiled Docs: Godot 4 Export](https://doc.mapeditor.org/en/latest/manual/export-tscn/)
- [Sprite Fusion](https://www.spritefusion.com/)
- [OpenGameArt: 16x16 Pixel Forest Tileset](https://opengameart.org/content/free-sample-16x16-pixel-forest-tileset-%E2%80%93-top-down-rpg-style)
- [OpenGameArt: 16-bit TopDown Zelda-Like](https://opengameart.org/content/16-bit-tileset-topdown-zelda-like-pro-version)
- [White Giant RPG: Godot 4 TileSet Scripting Migration](https://whitegiantrpg.com/godot-4-migration-tile-set-scripting/)
