"""Exporta el robot y el rifle seleccionados a GLB desde Blender."""
import sys
from pathlib import Path

import bpy
from mathutils import Quaternion, Vector

mode = sys.argv[sys.argv.index('--') + 1]
root = Path(__file__).resolve().parents[1]
out = root / 'assets' / 'models'
out.mkdir(parents=True, exist_ok=True)

bpy.ops.object.select_all(action='DESELECT')

if mode == 'robot':
    armature = bpy.data.objects['Armature']
    # Posar las manos con los controladores IK originales produce una postura
    # mucho más natural que rotar el hombro directamente.
    def set_rotation(name, axis, angle):
        bone = armature.pose.bones[name]
        basis = bone.bone.matrix_local.to_quaternion()
        bone.rotation_mode = 'QUATERNION'
        bone.rotation_quaternion = basis.inverted() @ Quaternion(Vector(axis), angle) @ basis

    def pose(frame, stride=0.0, jump=0.0):
        bpy.context.scene.frame_set(frame)
        for side, sign in [('L', 1), ('R', -1)]:
            hand = armature.pose.bones[f'hand ik.{side}']
            matrix = hand.matrix.copy()
            matrix.translation = Vector((sign * 0.55, -0.35 + sign * stride * 0.25,
                                         1.32 + jump * 0.2))
            hand.matrix = matrix
            hand.keyframe_insert(data_path='location', frame=frame)
        set_rotation('upper leg.L', (1, 0, 0), stride + jump)
        set_rotation('upper leg.R', (1, 0, 0), -stride + jump)
        for name in ('upper leg.L', 'upper leg.R'):
            armature.pose.bones[name].keyframe_insert(data_path='rotation_quaternion', frame=frame)

    armature.animation_data_create()
    for name, frames in {
        'Idle': [(1, 0.0, 0.0), (25, 0.0, 0.0)],
        'Walk': [(1, 0.0, 0.0), (7, 0.45, 0.0), (13, 0.0, 0.0),
                 (19, -0.45, 0.0), (25, 0.0, 0.0)],
        'Jump': [(1, 0.0, 0.0), (8, 0.0, 0.38), (18, 0.0, 0.0)],
    }.items():
        for existing_track in armature.animation_data.nla_tracks:
            existing_track.mute = True
        action = bpy.data.actions.new(name)
        armature.animation_data.action = action
        for frame, stride, jump in frames:
            pose(frame, stride, jump)
        track = armature.animation_data.nla_tracks.new()
        track.name = name
        track.strips.new(name, 1, action)
        armature.animation_data.action = None
    for track in armature.animation_data.nla_tracks:
        track.mute = False
    bpy.context.scene.frame_set(1)
    selected_names = {'Armature', 'Cube.002'}
    target = out / 'white_bot.glb'
elif mode == 'rifle':
    selected_names = {'SciFi_gun.010'}
    target = out / 'carbine_rifle.glb'
else:
    raise ValueError(mode)

for name in selected_names:
    obj = bpy.data.objects.get(name)
    if obj is None:
        raise RuntimeError(f'Falta el objeto {name}')
    obj.select_set(True)

bpy.context.view_layer.objects.active = bpy.data.objects[next(iter(selected_names))]
bpy.ops.export_scene.gltf(
    filepath=str(target), export_format='GLB', use_selection=True,
    export_yup=True, export_animations=True, export_image_format='AUTO',
    export_animation_mode='NLA_TRACKS',
)
print('EXPORTED:', target, 'BYTES:', target.stat().st_size)
