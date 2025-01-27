let teapot = loadObj("data/meshes/teapot.obj")

teapot.objectToWorld = mat4(1.0).translate(vec3(0.0, 0.0001, -12.0))
teapot.worldToObject = teapot.objectToWorld.inverse


let objects = @[
  Object(
    name: "teapot",
    geometry: teapot,
    material: Material(albedo: vec3(0.6, 0.9, 0.2))
  ),
  Object(
    name: "ground",
    geometry: initPlane(objectToWorld = mat4(1.0)),
    material: Material(albedo: vec3(0.4))
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
  cameraToWorld: mat4(1.0).rotate(X_AXIS, degToRad(-12.0))
                          .translate(vec3(0.0, 5.5, 1.5))
)

