"""Regenera las escenas estáticas de los niveles 3 a 5."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
ONLY_LEVELS = {int(value) for value in sys.argv[1:]} if __name__ == '__main__' and len(sys.argv) > 1 else {3, 4, 5}
COLORS = {
    'floor': (0.22, 0.28, 0.36), 'wall': (0.16, 0.21, 0.29),
    'barrier': (0.9, 0.52, 0.34), 'small': (0.95, 0.82, 0.34),
    'normal': (0.59, 0.56, 0.95), 'large': (0.59, 0.56, 0.95),
    'goal': (0.24, 0.8, 0.59), 'lava': (1.0, 0.22, 0.03),
}


def vec(values):
    return 'Vector3(' + ', '.join(str(v) for v in values) + ')'


class Level:
    def __init__(self):
        self.resources = []
        self.nodes = ['[node name="Environment" type="Node3D"]']
        for name, color in COLORS.items():
            self.resources.append(
                f'[sub_resource type="StandardMaterial3D" id="Mat_{name}"]\n'
                f'albedo_color = Color({color[0]}, {color[1]}, {color[2]}, 1)\nroughness = 0.8'
                + ('\nemission_enabled = true\nemission = Color(0.8, 0.12, 0.01, 1)\nemission_energy_multiplier = 0.5' if name == 'lava' else '')
            )

    def block(self, name, position, size, material='floor', swap=None):
        self.resources.extend([
            f'[sub_resource type="BoxMesh" id="Mesh_{name}"]\nsize = {vec(size)}',
            f'[sub_resource type="BoxShape3D" id="Shape_{name}"]\nsize = {vec(size)}',
        ])
        group = ' groups=["swappable"]' if swap is not None else ''
        props = f'position = {vec(position)}'
        if swap is not None:
            props += f'\nscale = {vec((swap,) * 3)}\ncollision_layer = 2\ncollision_mask = 0\nmetadata/size = {float(swap)}'
        self.nodes.append(
            f'[node name="{name}" type="StaticBody3D" parent="."{group}]\n{props}\n\n'
            f'[node name="Malla" type="MeshInstance3D" parent="{name}"]\nmesh = SubResource("Mesh_{name}")\nmaterial_override = SubResource("Mat_{material}")\n\n'
            f'[node name="Colision" type="CollisionShape3D" parent="{name}"]\nshape = SubResource("Shape_{name}")'
        )

    def box(self, name, x, z, scale, base=0):
        self.block(name, (x, base + 0.625 * scale, z), (1.25,) * 3,
                   'small' if scale == 0.5 else 'large', scale)

    def platform(self, name, x, z, width, length, top=0):
        self.block(name, (x, top - 0.3, z), (width, 0.6, length))

    def tunnel(self, z, width=10):
        # Un hueco central de 2 unidades; el resto es una pared alta.
        for x, suffix in [(-(width + 2) / 4, 'Izq'), ((width + 2) / 4, 'Der')]:
            self.block('Tunel' + suffix, (x, 3, z), ((width - 2) / 2, 6, 1.6), 'barrier')
        self.block('TechoTunel', (0, 3.575, z), (2, 4.85, 1.6), 'barrier')

    def walls(self, start, end, width=10, base=0):
        for x, name in [(-width / 2 - 0.25, 'ParedIzq'), (width / 2 + 0.25, 'ParedDer')]:
            self.block(name, (x, base + 3, (start + end) / 2), (0.5, 6, start - end), 'wall')
        self.block('ParedFinal', (0, base + 3, end - 0.25), (width + 1, 6, 0.5), 'wall')

    def goal(self, x, z, top):
        self.nodes.append(
            f'[node name="Meta" parent="." instance=ExtResource("GoalScene")]\nposition = {vec((x, top, z))}'
        )

    def save(self, number):
        if number not in ONLY_LEVELS:
            return
        self.resources.append('[sub_resource type="Environment" id="Ambiente"]\nbackground_mode = 1\nbackground_color = Color(0.06, 0.09, 0.15, 1)\nambient_light_source = 2\nambient_light_color = Color(0.65, 0.72, 0.82, 1)\nambient_light_energy = 0.65')
        self.nodes.extend([
            '[node name="Luz" type="DirectionalLight3D" parent="."]\nrotation = Vector3(-0.96, -0.44, 0)\nlight_energy = 1.4\nshadow_enabled = true\ndirectional_shadow_mode = 2',
            '[node name="Ambiente" type="WorldEnvironment" parent="."]\nenvironment = SubResource("Ambiente")',
        ])
        shared_goal = '[ext_resource type="PackedScene" path="res://goal.tscn" id="GoalScene"]'
        text = f'[gd_scene load_steps={len(self.resources) + 2} format=3]\n\n' + '\n\n'.join([shared_goal] + self.resources + self.nodes) + '\n'
        (ROOT / f'environment_{number}.tscn').write_text(text, encoding='utf-8')


def scene(number, spawn, size=1, spawn_x=0):
    if number not in ONLY_LEVELS:
        return
    text = (ROOT / 'main.tscn').read_text(encoding='utf-8')
    text = text.replace('res://environment.tscn', f'res://environment_{number}.tscn')
    text = text.replace('siguiente_nivel = "res://level_2.tscn"',
                        'es_nivel_final = true' if number == 5 else f'siguiente_nivel = "res://level_{number + 1}.tscn"')
    text = text.replace('0, 0.1, 3)', f'{spawn_x}, 0.1, {spawn})\ntamano_inicial = {float(size)}\nlava_kill_y = -1.5')
    (ROOT / f'level_{number}.tscn').write_text(text, encoding='utf-8')


def size_puzzle(level, gate_z, top=0, with_goal=True):
    # La caja está en el carril derecho, visible desde la entrada.
    # Los apoyos forman una escalera lateral de 0.8 -> 1.6 -> caja 2.5 -> salida 3.4.
    # El techo impide entrar con tamaño 2; tamaño 1 cabe con 0.25 de margen.
    # Viga delgada: la cámara puede ver las cajas por encima. Su cara superior
    # a 2.6 supera el salto máximo del jugador grande (~2.33).
    level.block('PasoNormal', (0, top + 2.325, gate_z), (10, 0.55, 1.2), 'barrier')
    level.box('CajaNormal', -2.8, gate_z + 2.5, 1, top)
    level.block('ApoyoBajo', (-2, top + 0.4, gate_z - 2.6), (2, 0.8, 2))
    level.block('ApoyoAlto', (0, top + 0.8, gate_z - 3), (1.4, 1.6, 2))
    level.box('CajaEscalon', 2, gate_z - 3, 0.5, top)
    level.platform('SalidaElevada', 0, gate_z - 7, 10, 4, top + 3.4)
    if with_goal:
        level.goal(0, gate_z - 7.5, top + 3.4)


def build():
    level = Level()
    level.platform('Suelo', 0, -6, 10, 26)
    level.walls(7, -19)
    level.tunnel(0)
    level.box('CajaPequena', 2, 3, 0.5)
    level.box('CajaGrande', 2, -6, 2)
    level.platform('SalidaElevada', 0, -16, 10, 6, 1.9)
    level.goal(0, -16, 1.9)
    level.save(3)
    scene(3, 5)

    level = Level()
    level.platform('Suelo', 0, -1, 10, 16)
    level.walls(7, -9)
    size_puzzle(level, 1)
    level.save(4)
    scene(4, 2.8, 2, spawn_x=2)

    level = Level()
    level.block('Lava', (0, -2.5, -12), (22, 1, 48), 'lava')
    level.platform('IslaA', 0, 2, 10, 12)
    level.tunnel(3)
    level.box('CajaPequena', 2, 6, 0.5)
    level.box('CajaGrande', 2, -1, 2)
    # A termina en -4; B empieza en -8. Salto horizontal de 4 unidades.
    level.platform('IslaB', 0, -15, 10, 14, 1.7)
    level.walls(-8, -22, base=1.7)
    # Abrir el extremo del corredor para saltar desde la salida a la isla C.
    level.nodes = [node for node in level.nodes if 'name="ParedFinal"' not in node and 'parent="ParedFinal"' not in node]
    size_puzzle(level, -12, 1.7, with_goal=False)
    # Salida: borde -21; isla final: borde -23. Salto de 2 unidades, mismo nivel.
    level.platform('IslaC', 0, -25.5, 8, 5, 5.1)
    level.goal(0, -25.5, 5.1)
    level.save(5)
    scene(5, 6.7)


if __name__ == '__main__':
    build()
