let objects = @[
  Sphere(o: point(0.0, 0.0, -10.0),
         r: 2,
         albedo: vec3(0.3, 0.9, 0.2)),

#  Sphere(o: point(1.3, 0.0, -8.0),
#         r: 0.2,
#         albedo: vec3(1.0, 0.3, 0.5)),

  Plane(o: point(0.0, -2.0, 0.0),
        n: vec(0.0, 1.0, 0.0),
        albedo: vec3(1.0, 1.0, 1.0))
]

var lights = newSeq[Light]()

lights.add(
  DistantLight(color: vec3(1.0), intensity: 1.0,
               dir: vec(-2.0, -0.8, -1.3).normalize))

#lights.add(
#  DistantLight(color: vec3(1.0, 0.0, 0.0), intensity: 2.0,
#               dir: vec(1.5, -0.5, -3.0).normalize))

var scene = Scene(
  objects: objects,
  lights: lights
)
