import glm

import geom, light, material


type
  Object* = ref object
    name*: string
    geometry*: Geometry
    material*: Material

type
  Scene* = ref object
    objects*: seq[Object]
    lights*: seq[Light]
    fov*: float
    cameraToWorld*: Mat4x4[float]
    bgColor*: Vec3[float]


proc `$`*(o: Object): string =
  result = "Object(name=" & o.name  & ", " &
    "geometry=" & $o.geometry & ", " &
    "material=" & $o.material & ")"

