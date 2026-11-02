"""Renderiza una vista de diagnóstico del GLB exportado."""
import sys
from pathlib import Path

import bpy
from mathutils import Vector

name = sys.argv[sys.argv.index('--') + 1]
root = Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(root / 'assets' / 'models' / (name + '.glb')))
if name == 'white_bot':
    armature = next(obj for obj in bpy.data.objects if obj.type == 'ARMATURE')
    print('ACTIONS:', [action.name for action in bpy.data.actions])
    if armature.animation_data:
        for track in armature.animation_data.nla_tracks:
            track.mute = True
        armature.animation_data.action = bpy.data.actions.get('Idle')
        bpy.context.scene.frame_set(1)
        for key in ('upper arm.L', 'lower arm.L', 'hand.L', 'upper arm.R', 'lower arm.R', 'hand.R'):
            bone = armature.pose.bones[key]
            print('POSE:', key, tuple(round(v, 2) for v in bone.tail - bone.head))

verts = [obj.matrix_world @ Vector(corner) for obj in bpy.data.objects
         if obj.type == 'MESH' for corner in obj.bound_box]
minimum = Vector(tuple(min(v[i] for v in verts) for i in range(3)))
maximum = Vector(tuple(max(v[i] for v in verts) for i in range(3)))
center = (minimum + maximum) / 2
print('BOUNDS:', name, list(minimum), list(maximum))

cam_data = bpy.data.cameras.new('PreviewCamera')
camera = bpy.data.objects.new('PreviewCamera', cam_data)
bpy.context.collection.objects.link(camera)
bpy.context.scene.camera = camera
camera.location = center + (Vector((5, -8, 3)) if name == 'white_bot' else Vector((4, 4, 3)))
camera.rotation_euler = (center - camera.location).to_track_quat('-Z', 'Y').to_euler()
camera.data.type = 'ORTHO'
camera.data.ortho_scale = max(maximum - minimum) * 1.8

scene = bpy.context.scene
scene.render.engine = 'BLENDER_WORKBENCH'
scene.display.shading.color_type = 'MATERIAL'
scene.display.shading.light = 'STUDIO'
scene.render.resolution_x = 800
scene.render.resolution_y = 800
scene.render.resolution_percentage = 100
scene.render.filepath = str(root / 'assets' / 'models' / (name + '_preview.png'))
bpy.ops.render.render(write_still=True)
