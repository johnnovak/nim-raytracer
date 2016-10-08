import glm


type
  Material* = ref object
    albedo*: Vec3[float]
    reflection*: float


proc `$`*(m: Material): string =
  result = "Material(albedo=" & $m.albedo & ")"

