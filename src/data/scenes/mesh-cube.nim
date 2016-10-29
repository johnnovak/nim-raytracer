let
  v = @[point(0.0, 0.0, 0.0), point(1.0, 0.0, 0.0), point(0.0, 1.0, 0.0)]
  n = @[vec(0.0, 0.0, 1.0), vec(0.0, 0.0, 1.0), vec(0.0, 0.0, 1.0)]
  t = Triangle(vertexIdx: [0, 1, 2], normalIdx: [0, 1, 2])
  f = @[t]

let cube = TriangleMesh(
  vertices: v,
  normals: n,
  faces: f,
  objectToWorld: mat4(1.0),
  worldToObject: mat4(1.0)
)

let objects = @[
  Object(
    name: "cube",
    geometry: cube,
    material: Material(albedo: vec3(0.6, 0.9, 0.2))
  )
]


var lights = newSeq[Light]()

lights.add(
  DistantLight(color: vec3(1.0), intensity: 4.0,
               dir: vec(-2.0, -0.8, -0.3).normalize)
)
lights.add(
  DistantLight(color: vec3(0.8, 0.3, 0.0), intensity: 1.0,
               dir: vec(2.0, -0.8, -1.3).normalize)
)


var scene = Scene(
  bgColor: vec3(0.01, 0.03, 0.05),

  objects: objects,
  lights: lights,

  fov: 50.0,
  cameraToWorld: mat4(1.0).translate(vec3(0.3, 0.3, 5.0))
)

