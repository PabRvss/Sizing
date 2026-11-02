"""Lista objetos y medidas de un .blend abierto con Blender en segundo plano."""
import bpy
from mathutils import Vector

print('BLEND:', bpy.data.filepath)
for obj in bpy.data.objects:
    if obj.type not in {'MESH', 'ARMATURE', 'EMPTY'}:
        continue
    bounds = [round(v, 3) for v in obj.dimensions]
    location = [round(v, 3) for v in obj.location]
    parent = obj.parent.name if obj.parent else '-'
    print('OBJECT:', obj.type, repr(obj.name), 'parent=', repr(parent),
          'location=', location, 'dimensions=', bounds,
          'polys=', len(obj.data.polygons) if obj.type == 'MESH' else '-',
          'bounds=', [(round(min(axis), 2), round(max(axis), 2)) for axis in zip(*[obj.matrix_world @ Vector(c) for c in obj.bound_box])] if obj.type == 'MESH' else '-')
