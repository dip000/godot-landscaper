
<p align="center">
	<img width="1180" height="417" alt="image" src="https://github.com/user-attachments/assets/7fb1ac6c-6e62-4316-8119-90ef22621c0b" />
</p>
<p align="center">
Chroma Alchemy, made with GodotLandscaper, by DIP (me, hehe)<br>
https://dip000.itch.io/chromalchemy
</p>
<br>

**🌟 Update**: Added BakedQuadGrass. A color-baked grass instancer for Quad meshes<br/>
<br/>
<br/>

## Content
2. ☑️ [BakedQuadGrass](#bakedquadgrass). A color-baked grass instancer for Quad MultiMeshes</br>
	2.1	☑️ Integrated with inspector</br>
   	2.2	☑️ Spawn-Paint grass individually</br>
   	2.3 ☑️ Per-instance configurations</br>
   	2.4 ☑️ Custom random size and random rotation on each axis</br>
   	2.5 ☑️ Save-Load individual resources</br>
   	2.6 ☑️ Undo-Redo on every action</br>
   	2.7 ❌ Chunkify in custom-sized parts</br>
   	2.8 ❌ Auto LOD chunks</br>
    2.9 ☑️ Total Compatibility render friendly</br>
    2.10☑️ Up to 4 grass variants per material</br>
3. ❌ TexturedQuadGrass. A textured grass instancer for Quad MultiMeshes
4. ❌ Baked3DInstancer. A color-baked instancer for 3D model MultiMeshes
5. ❌ Textured3DInstancer. A textured instancer for 3D model MultiMeshes
6. ❌ GroundBuilder. A terrain builder with height maps and vertex-baking 
7. ❌ GroundPainter. A hand-paintable terrain with basic texture mixing

# Trying This Add-On
Follow the next steps:
1. Download and install this Plugin. See [installing_plugins](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html)
2. Open a scene, and instantiate a 'BakedQuadGrass' node in the scene tree.
3. In the inspector, select "Spawn" or "Paint"
4. Drag over your terrain to start landscaping!

# BakedQuadGrass
![demo](https://github.com/user-attachments/assets/f68840e9-5aa8-452a-ad65-9259c7cd97dd)

Brush that spawns and paints grass over any terrain when you brush over it.<br />
The biggest advantage is that its colors will be "baked" into the instances, and the bottom of the grass will automatically take the color of the terrain. No need for textures or aligning to the terrain.
<br /><br />
Another advantage is that it sticks and aligns to any surface.
<br />
The downside, of course, is that it takes more GPU memory to store extra data, but it can be mitigated by chunking the multimesh instances.
<br /><br />
Spawns with left-click to build a new mesh, and paint with right-click.<br />
Properties:
* **Parent Node:** The holder of the resulting multimeshes, it defaults to itself.<br />
* **Spawn Ratio:** The amount of grass that might hit the scanned terrain per frame<br />
* **Erase Ratio:** The chances of erasing grass per frame. Makes for a smoother experience, probably<br />
* **Quality:** The amount of horizontal subdivisions. Animations and gradients are better.<br />
* **Splash Height:** The splash color gradient from the ground to the top of the grass<br />
* **Primary Color:** To paint the top of the grass. Use with left click<br />
* **Secondary Color:** To paint the bottom of the grass. Use with right click<br />



# Addressing Current Caveats
About Spaghetti Code:
* Well, it has gotten a lot better than the previous version. Still working on cleaning up, but that'll have to wait a bit until the rest of the landscaping tools are made

About Properties Not Updating Correctly:
* Ugh, don't get me started on export setter vars, I'll do it later

About Backward Compatibility:
* As compatible as water and oil with the previous version. Don't even think about it

About Shading or Un-cartooning The Meshes:
* I think this project will stay cartoonish-looking for some time 


# Author notes
Hi, nickname's DIP. Thanks for passing by!<br />

I'd be glad to hear what you have to say about the grass shader [HERE](https://godotshaders.com/shader/stylized-cartoon-grass/). Or contact me about this plugin at [ab-cb@hotmail.com](mailto:ab-cb@hotmail.com?subject=[GitHub]%20Godot%20Landscaper%20Plugin)<br />
See ya!<br />

*And for those who sent their feedback, thank you very much!*
