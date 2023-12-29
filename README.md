# Godot Landscaper
Terrain builder, terrain texturizer, grass scatterer, and grass colorer. Based on textures and paintbrushes
![landscaper](https://github.com/dip000/godot-landscaper/assets/58742147/011ccfec-2462-463b-85aa-925e1c63936d)




## Content
1. [Features And How To Use Them](#1-features-and-how-to-use-them)
	- [Terrain Builder](#11-terrain-builder)
	- [Terrain Color](#12-terrain-color)
	- [Terrain Height](#13-terrain-height)
	- [Grass Color](#14-grass-color)
	- [Grass Spawn](#15-grass-spawn)
3. [Performance Concerns](#performance-concerns)
4. [Roadmap To Beta And Asset Library](#roadmap-to-beta-and-asset-library)
5. [Author Notes](#author-notes)



# 1. Features And How To Use Them
Follow the next steps:
1. Download and install this Plugin. See [installing_plugins](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html)
2. Open a scene, and instantiate a 'SceneLandscaper' node in the scene tree. It will create a new terrain template
3. Select the 'SceneLandscaper' node and go to the "Landscaper" tab over the right dock.
4. Select your brush and click and drag over your terrain to start terra-brushing!

## 1.1 Terrain Builder
Brush that generates new mesh when you paint over the terrain.<br />
Paint white with left-click to build a new mesh, and paint black with right-click to erase.<br />

_Building terrain:_ <br />
![TerrainBuilder](https://github.com/dip000/godot-landscaper/assets/58742147/cac44f39-d5c2-4c84-b9d9-6c1a73512128)
<br />

## 1.2 Terrain Color
Brush that color-paints your created terrain.<br />
Paint with the selected color using left-click, use right-click to smooth the selected color.<br />

**Resolution** of the texture in pixels per meter.<br />
<br />


## 1.3 Terrain Height
Brush that changes the height of your created terrain.<br />
Create mounds with left-click, and create ditches with right-click.<br />

**Max Height** is the relative height of the entire terrain.<br />
**Apply To All** Heighten or lowers the whole terrain evenly.<br />


## 1.4 Grass Color
Brush that color-paints your spawned grass.<br />
Paint with the selected color using left-click, use right-click to smooth the selected color.<br />
>Note that only the top of the grass is being colored. That's because the bottom half is taking the color of the terrain!<br />


## 1.5 Grass Spawn
Brush that spawns new grass over your created terrain.<br />
Spawn grass with left-click to spawn your selected grass variant or right-click to clear it<br />

* **Density:** How many grass instances are inside the area you have painted with this brush
* **Billboard:** Tipes of billboarding. BillboardY (grass always looks at the camera), CrossBillboard (for each grass, spawns another 90 degrees in the same position), and Scatter (Scatters the grass with random rotations)
* **Enable Details:** Renders the details of your grass variant texture. These are the sharp margin edges in the preview grass shown here
* **Detail Color:** Recolor of your details
* **Quality:** Subdivisions for each blade of grass. This affects its sway animation and gradient color smoothness (because is vertex colored)
* **Size:** Size of the average blade of grass in meters
* **Gradient Value:** The color mix from the grass roots to the top as seen from the front. BLACK=terrain_color and WHITE=grass_color
* **Variants:** A list of the grass textures to show. Uses the preview images shown here. Does not create extra materials but is capped at 4


# Performance concerns
About Textures:
* Terrain and Grass color textures are stored in separate files as PNG and their size in pixels is calculated as "resolution*world_size". This means that the file is as big as the terrain's bounding box.
* Terrain and Grass color textures are not mipmapped (LOD) internally but after saving the project, they will be mipmapped automatically.
* Every texture except colored ones, are stored in a "project.tres" file. They are not relevant for end-products and the project file itself can be deleted if the user doesn't want to edit the landscape anymore.

About Grass:
* This version now supports GL Compatibility rendering! But it is limited to one grass variant due to the lack of shader instance variables in Compatibility
* Coloring the grass is optimized by using vertex colors. This means that the shader is only coloring as less as 4 vertex per instance (The vertices of a square)
* You can set how many vertex to use per grass in "GrassSpawn Brush > Quality"
* Grass chunking has not been implemented yet.


# Roadmap to Beta and Asset Library
1. [X] Save and bake textures, shaders, and materials in the user folder
	- [X] Keep TerraBrush open for modifications
	- [X] Clear all plugin dependencies. Like in [this repository for shaders](https://github.com/dip000/my-godotshaders/tree/main/StylizedCartoonGrass)

2. [X] Add support for multiple grass billboarding options
	- [X] Cross billboard
	- [X] Billboard Y
 	- [X] Scatter

3. [X] Add Terrain generator brush
	- [X] Click over the terrain and create a mesh surface
	- [X] Meshes are ImmediateMesh that are generated dynamically instead of using a shader

4. [X] Dedicated UI for paintbrushes
	- [X] Custom control in rightmost Dock
	- [X] Recouple brushes for this new system

5. [ ] Add Instancer Brush
	- [ ] Use the same logic as the grass spawner but with custom scenes instead of grass

6. [ ] Asset Library friendly
   - [ ] [asset library requirements](https://docs.godotengine.org/en/stable/community/asset_library/submitting_to_assetlib.html)
   - [ ] In-code Documentation following [style guides](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html#doc-gdscript-styleguide)


# Author notes
Hi, nickname's DIP. Thanks for passing by!<br />
I'd be glad to hear what you have to say about the grass shader [here](https://godotshaders.com/shader/stylized-cartoon-grass/). Or contact me about this plugin at [ab-cb@hotmail.com](mailto:ab-cb@hotmail.com?subject=[GitHub]%20Godot%20Landscaper%20Plugin)<br />
See ya!<br />
