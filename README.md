
https://github.com/user-attachments/assets/e6faebd4-d146-494a-9d54-636cef62c6c4

<br>

**🌟 Update**: Released v0.3 to the main branch.<br/>
<br/>

## What Is This?
Godot Landscaper is an editor add-on for painting terrain and grass using brush-based workflows, non-destructive effects, and GPU-friendly batching. Only tested for Godot 4.6
<br/>

# **Trying This Add-On**
### [1/2] Start with these steps
1. Download and install this Plugin. See how in [installing_plugins](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html)
2. Open a scene and add a **GLTerrainController** or a **GLGrassController** node in the scene tree.
3. Select your controller and choose a brush tab from the inspector, like **Build** or **Spawn**
4. Drag the brush over your terrain to start landscaping!
<br/>

### [2/2] Understanding *Brush* And *Effects* Systems
The brush system can be summarized with the following steps:
- **On Controller Selected**. Changes the top-level orchestrator (Grass or Terrain)
- **On Inspector Tab Selected**. Changes the brush logic block (spawn grass, build terrain, paint color, etc.)
- **On 3D GUI Input**. Runs a stroke-like interface over the selected controller with the selected brush:
	- **On Stroke Start**. Caches, initializations, might lagspike a bit.
	- **While Primary**. Brush smoothly with the Right Mouse Button.
	- **While Secondary**. Brush smoothly with the Left Mouse Button.
	- **Stroke End**. Cleanup, stores into **Source BuildData**.
	- **Build** Uses **Source BuildData** to apply changes.
<br/>

And when you're satisfied with the brush stroke, try the **Apply All Effects** button. This..
- Grabs the **Source BuildData**, copies into a **Processed BuildData**.
- Feeds **Processed BuildData** to the **Effects Stack**.
- Each effect uses the processed data to make (or clear) changes.
- Builds the result at the end.
<br/>

This means that..
> ***Effects are offline non-destructive modifiers for production (see GIF above)***
<br/>


# **⭐ Features Index ⭐**
1. [**Base Features**](#1-base-features). These features are shared among all landscaper controllers
   	- [x] Save / Load From Build Data
	- [x] Effects Stack
	- [x] Unlimited Instances And Per-Instance Customization
	- [x] All Rendering Targets / WebGL / Compatibility / Forward / Mobile
	- [x] Surface Scanner For Mesh / Material / Textures / Colors
	- [ ] Undo / Redo


2. [**GrassController**](#2-grasscontroller). A hand-paintable color-baked grass instancer for textured and non-textured 3D MultiMeshes
	- [x] Spawn Brush
 	- [x] Paint Brush
	- [x] Effects
		- [x] Chunkify
		- [x] LoD / Visibility Ranges
		- [x] Color Re-Scanner
		- [x] Level Re-Scanner
	  	- [x] Texture Exporter
	   	- [ ] Texture Overlay
    	- [ ] LUT Maps
	    - [ ] Impostor Swapping


3. [**TerrainController**](#3-terraincontroller). A hand-paintable vertex terrain builder with height mapping and brush coloring</br>
	- [x] Build Brush
	- [x] Height Brush
	- [x] Paint Brush
	- [x] Effects
		- [x] Chunkify
		- [x] LoD / Visibility Ranges
	  	- [x] Texture Exporter
		- [x] Round Corners
  		- [x] Heightmap Collider
	- [x] Vertex Indexing
	- [x] Mesh LoD

</br>
</br>

# 1. Base Features
## Save and Load
The save and load system is straightforward:
1. Place a BuildData resource under **"GLController > Source"**. A BuildData resource can be obtained from:
   - Previously saved from your filesystem
   - Created with Godot's context menu **"New GLBuildDataGrass"**, for example. And filled with your own resources.
   - Auto-created when used without configuring anything. GrassController will load templates, and TerrainController will load all default resources needed
2. Optionally, select your target node. GrassController as MultiMeshInstance3D and TerrainController has MeshInstance3D. If no node was selected, it will create one under the controller.
2. Press **Build From Source**. This will use the source build data to construct the target controller.
</br>

## Effects Stack
1. Select a controller like GLTerrainController.
2. Having built a terrain mesh, go to the effects stack under **"GLController > Effects"**
3. Add an effect from Godot's context menu **"New GLRoundCorners"**, for example.
4. Press "**Apply All Effects**". And watch how it cuts the outer sharp corners
5. Remember to clear effects before continuing to edit your terrain, or the results might not be as expected.
6. You can stack all effects you want for that controller, or even make your own
</br>

## Unlimited Instances
You can theoretically add any number of controllers to the scene, as simple as that. 
</br>

## Rendering Targets
The reason I'm even making this is that I needed tools with full compatibility, so here we are.
Some random notes about compatibility:
- In Compatibility mode, the grass shader needs to convert sRGB to linear manually since the colors are sourced from CUSTOM and COLOR variables, and they do not get converted as they were samplers.
- Web exports do not allow indexing arrays of textures, nor do they allow the shader change the preallocated array size. So anyway, Texture2DArray is more performant, so who cares.
</br>

## Surface Scanner
The Scanner adds functionality to the native physics raycaster. Using PhysicsDirectSpaceState3D.intersect_ray(), you get pretty usefull data from the intersection, most often than not however, this is not enough. Presenting..
- Scan Mesh Instance. Finds the mehs instance the CollisionObject3D belongs to.
- Scan Color Sources. Finds materials, textures, and colors and wraps them in a MeshDataTool.
- Create Surfaces. Instantiates new colliders over the physics body that match their material shapes. One collider for each material detected.
- Scan Color. From the collider face and shape index hit, and using the found color sources, matches the exact pixel texture hit.
</br>

**Caveats**:
- There's a limit to one mesh per PhysicsBody3D configured in Ground Coloring > Scan Meshes. Though the scanner does find any number of materials, textures, and colors.
- Scanning for shader shenanigans like detail textures, UV transforms, etc, is not a viable thing to simulate to paint the bottom of the grass instances. Best I can do is find the main texture with Ground Coloring > Scan Color Sources, or manual paint with "paint_with_sencondary_color"
</br>

## Undo-Redo
Not implemented yet because I've had problems with clearing the history correctly, throwing errors, and blocking the entire scene from being edited. The way to implement this is extremely easy since the comand pattern is already there.
</br>
</br>

# 2. GrassController
## Spawn Brush 
> Instances or erases grass over any surface when you brush over it, auto coloring the bottom with the scanned terrain color.
</br>
<p align="center">
	<img height="200px" src="https://github.com/user-attachments/assets/9f8055fa-cb6e-4821-b752-a9767b2a4d29" />
</p><br />

- **Multimesh Instance:** The MultiMeshInstance3D node reference in scene. A MultiMeshInstance3D will be auto-created if none is selected, it will also be built with BuildData if provided.<br />
- **Spawn Ratio:** The amount of grass that might hit the scanned terrain per frame<br />
- **Erase Ratio:** The chances of erasing grass per frame. Good for decreasing the density instead of hard-cutting all instances<br />
</br>

## Paint Brush
> Paints grass instances when you brush over them.
</br>
<p align="center">
	<img height="200px" src="https://github.com/user-attachments/assets/afdc4cb2-102d-442c-81a1-deba99bd554e" />
</p><br />

* **Splash Height:** The splash color gradient from the ground to the top of the grass<br />
* **Primary Color:** To paint the top of the grass. Use with left click<br />
* **Secondary Color:** To paint the top of the grass, optionally the bottom (see below). Use with right click<br />
* **Paint Bottom With Secondary** If enabled, paints th the bottom of the grass with secondary color instead of scanning the ground color automatically.
</br>

### Rambling About MultiMesh Colors, Please Skip.
Painting colors uses MultiMesh.use_colors (COLOR) and MultiMesh.use_custom (CUSTOM) to store the top and bottom colors of each grass instance, respectively.

Pros of using COLOR and CUSTOM as storage instead of a texture sampler:
- The colors will be "baked" into the instances, there is no need to sample any texture.
- No struggle to sync the bottom color texture with the terrain because it is not a spatially placed texture, no texture offset calculations. The color "sticks" to the instance.
- Since the instances are not tied to a texture, that means that they can be freely placed anywhere, regardless of instance. With textures that'd mean a potentially giant texture with empty gaps.

Cons of using COLOR and CUSTOM as storage instead of a texture sampler:
- It needs to store 2 extra vec4 per instance on the GPU memory, and that might not scale well with hundreds of thousands of instances. However, this can be mitigated by chunking the multimesh instances so the GPU loads in batches. Well is not like using textures is free either.
- As mentioned before, Compatibility needs to convert these colors from sRGB to linear. Textures can do that automatically.
<br />


## Effects
### Chunkify
Using individual MeshInstance3D nodes is almost as bad as not chunkifying a giant MultiMeshInstance3D. So this is a mandatory step for any real tool.
This effect separates the MultiMeshInstance instances in batches so the GPU has some respite. A chunk size of 32x32 is a good start.

Note: Different hardware has different amounts of memory to spare for shaders for each mesh, so smaller chunks may be needed for potato machines.
</br>

### LoD - Visibility Range
It only modifies the GeometryInstance3D.visibility_range_end and MultiMesh.visible _instances of the MultiMeshInstence, these properties are passed to the chunks as well.
</br>

### Texture Exporter
By default, the landscaper will use a Texture2DArray to process images, but only Godot's native importer has the ability to compress textures into CompressedTexture2DArray. To make this work, this effect saves the texture into the filesystem using a custom ConfigFile *.import file with the following parameters:
- `importer=2d_array_texture`. Saves as a CompressedTexture3DArray, the default is CompressedTexture2D, so this is a must.
- `compress/channel_pack=2`. Uses only the RB color channels for the detail mask and alpha. The actual colors are given by the grass coloring brush.
- `mipmaps/generate=true`. A must for 3D texture assets. As a side effect, the mipmaps bleed into the neighbor textures. Use a margin to mitigate this (I tried to do it by code, but it doesn't work for some reason)
- `slices/horizontal` as the number of layers (textured grass instances) used.
- `slices/vertical=1`. The result is a lineal array, not a box, for simplicity.
- `compress/mode` as `VRAM Compressed` or `Basis Universal`. According to the docs, "Size on disk is reduced, and video memory usage is also decreased considerably."
</br>

### Color Re-Escanner
Since the terrain texture will most likely be updated, the baked grass colors will no longer match. In this case, apply the Color Re-Escanner effect to update the ground colors to match the bottom texture or color.
</br>

### Level Re-Escanner
The same as the Color Re-Scanner, but with terrain height updates. Use this when the terrain height changes to level the grass to the correct positions.
</br>

### Texture Overlay
Shading with grass is a big performance eater. The recommended route to shade grass is to:
- Shade manually with darker colors at the bottom (possible by using paint_bottom_with_secondary_color=true)
- Use a texture mix over the result for dynamic shade, like clouds

This feature is not implemented, but you're free to modify the grass shader provided to add it.
</br>

### LUT Maps
Same with Texture overlays, shading is too expensive, so Look Up Table Maps exist. LUT mapping is a technique for remapping colors. A simple implementation is:
- Create a GradientTexture1D with a pretty color palette, this will be the LUT Map.
- In the shader, calculate the luminance per pixel.
- Index the map with the luminance value. This will return a different color than the original

This feature is not implemented, but you're free to modify the grass shader provided to add it.
</br>

### Impostor Swapping
For rendering millions of grass in larger maps, culling, LoD, chunks, and Mipmaps won't cut it anymore, you need to consider changing the entire MultimeshInstance for a Sprite3D over very long distances. This effect will do just that using Godot's HLOD system.

This feature is not implemented.
</br>
</br>


# 3. TerrainController
## Build Brush
> Creates or erases mesh over a grid in the XZ axis when you brush over it.
</br>
<p align="center">
	<img height="200px" src="https://github.com/user-attachments/assets/c4ac97d5-9045-402c-a303-3087c08bb6c7" />
</p><br />

- **sew_seams_on_build**. Joins hard edges with the closest cells.
- **terrain**. The MeshInstance3D terrain node reference.
</br>

## Height Brush
> Heightens or lowers mesh over a grid in the XZ axis when you brush over it.
</br>
<p align="center">
	<img height="200px" src="https://github.com/user-attachments/assets/b08d2eb7-654c-430f-9adb-f12116012508" />
</p><br />

- **strenght**. Controls how much the terrain is raised or lowered per stroke. Higher values produce steeper hills and deeper depressions. Lower values allow for subtle shaping and fine adjustments.
- **ease_curve**. Controls how the brush strength fades from the center toward the edges. Lower values create a softer, wider influence. Higher values concentrate the effect near the center for sharper shapes.
- **level**. Flattens the affected terrain towards the minimum height if using the primary key. Flattens to the max height if using secondary.
</br>

## Color Brush
> Colors the terrain texture when you brush over it.
</br>
<p align="center">
	<img height="200px" src="https://github.com/user-attachments/assets/62c2947a-5a67-4648-bea6-efd34f1287ba" />
</p><br />

. **primary_color**. Terrain color with the left mouse button. Use transparency for smooth blending.
. **secondary_color**. Terrain color with the right mouse button. Use transparency for smooth blending.
- **brush_shape**. The splat texture to brush with. Use alpha gradients for a smooth falloff.
</br>


## Effects
### Chunkify
A straightforward split, UV maps are renormalized to cover the entire mesh bounds, and each chunk gets to keep its part of the texture. This means that the texture is not split, and the material uses the same texture for every chunk.
</br>

### Visibility Range LoD
Modifies the GeometryInstance3D.visibility_range_end of the terrain MeshInstance3D. This property is passed to the chunks as well.
</br>

### Texture Exporter
Different from the grass texture, which is very restrictive, this texture exporter has unnecessarily many options to format the output terrain texture.
</br>

### Round Corners
My personal favorite, it just changes the square shape for a triangle if there are no cell neighbors. Looks better and saves a few vertices.
</br>

### Heightmap Collider
Changes the original Collision Trimesh Shape, which may be very costly, to a lightweight HeightmapCollisionShape. Holes and gaps in the terrain will be covered since the heightmap is a continuous plane.
</br>

## Mesh LoD
Uses ImporterMesh to create mesh LoD.
This is a feature that runs by default in the builder itself. This means that it does not require an effect to be applied.
</br>

## Vertex Indexing
Sometimes called vertex welding. Uses Mesh.ARRAY_INDEX capabilities to share vertex data. For example, if a square is made out of two triangles, that's 6 vertices, and two squares are 12, but by indexing the shared vertices, you're saving all of the extra vertex data. This scales incredibly well for thousands upon thousands of vertices.

This is a feature that runs by default in the builder itself. This means that it does not require an effect to be applied.
</br>
</br>

# Author notes
Hi, nickname's DIP. Thanks for passing by!<br />

I'd be glad to hear what you have to say about this addon. Contact me at [ab-cb@hotmail.com](mailto:ab-cb@hotmail.com?subject=[GitHub]%20Godot%20Landscaper%20Plugin)<br />
See ya!
<br />
</br>

# Self Promotions Here
If you like my work, consider looking at my other works..
[Chroma Alchemy, by DIP](https://dip000.itch.io/chromalchemy)

<br>
<a href='https://ko-fi.com/O4O61JATV3' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi6.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
