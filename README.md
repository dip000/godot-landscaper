
<p align="center">
	<img src="https://github.com/user-attachments/assets/5d146bd7-3ef8-48fd-9244-a2cfacf804f8"/>
</p>
<br>

**🌟 Update**: Added Auto-scan multiple color sources and rescanning tools<br/>
**🌟 Update**: Added Chunkifyier, Auto LODs and visibility ranges<br/>
**🌟 Update**: Added BakedQuadGrass. A color-baked grass instancer for Quad meshes<br/>
<br/>
<br/>

## Content
1. ☑️ [**QuadGrassTool**](#quadgrasstool). A hand-paintable color-baked grass instancer for Quad MultiMeshes</br>
	1.1	☑️ Auto Scans Ground Color</br>
   	1.2	☑️ Paints Top / Bottom individually</br>
   	1.3 ☑️ Chunkify</br>
   	1.4 ☑️ LODs / Visibility</br>
   	1.5 ☑️ Undo / Redo</br>
   	1.6 ☑️ Save / Load Project</br>
   	1.7 ☑️ Per-Instance Configurations (up to 4)</br>
   	1.8 ☑️ Full Rendering/Web Compatibility</br>
	1.9 ☑️ Rotate / Scale / Translate, and it Still Works
2. ❌ **Grass3DTool**. A hand-paintable color-baked instancer for 3D model MultiMeshes
3. ❌ **PackedSceneTool**. A PackedScene instancer
4. ❌ **GroundBuilderTool**. A hand-paintable terrain builder with height maps and vertex-baking 

# Trying This Add-On
Follow the next steps:
1. Download and install this Plugin. See [installing_plugins](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html)
2. Open a scene, and instantiate a 'QuadGrassTool' node in the scene tree.
3. In the inspector, select "Spawn" or "Paint"
4. Drag over your terrain to start landscaping!

# QuadGrassTool
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
* **Anchor Mesh:** The parent for the generated MultiMeshInstance3D grass. Grass will be anchored to this node's position. <br />
* **Spawn Ratio:** The amount of grass that might hit the scanned terrain per frame<br />
* **Erase Ratio:** The chances of erasing grass per frame. Makes for a smoother experience, probably<br />
* **Splash Height:** The splash color gradient from the ground to the top of the grass<br />
* **Primary Color:** To paint the top of the grass. Use with left click<br />
* **Secondary Color:** To paint the bottom of the grass. Use with right click<br />



# Addressing Current Caveats
About Shading or Un-cartooning The Meshes:
* From my research, Godot developers use either very basic lighting or just not lighting at all in 3D.
* This will be added, eventually

About Undo/Redo History throwing errors:
* When you try to save a project file, the Inspector UndoRedo will be too bamboozled to work properly. I patched it by duplicating the resource and saving the scene, don't know why that works but ok 🤷‍♂️
* If any error happens, there will be a mismatch of commits, and it might get UndoRedo crazy. Kind of fixed it by spam-committing empty actions.
* If Nodes and properties do not seem to move or respond at all. The UndoRedo is probably the culprit, yet again. Restart the scene, and it should be ok

# Author notes
Hi, nickname's DIP. Thanks for passing by!<br />

I'd be glad to hear what you have to say about this addon. Contact me at [ab-cb@hotmail.com](mailto:ab-cb@hotmail.com?subject=[GitHub]%20Godot%20Landscaper%20Plugin)<br />
See ya!<br />

*And for those who sent their feedback, thank you very much!*
