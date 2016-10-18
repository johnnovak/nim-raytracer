var objects = @[
  Object(
    name: "ground",
    geometry: initPlane(objectToWorld = mat4(1.0)),
    material: Material(albedo: vec3(0.4))
  ),
  Object(
    name: "box",
    geometry: initBox(
      objectToWorld = mat4(1.0).translate(vec3(0.0, 1.0, -10.0)),
      vmin = vec(-1.0, -1.0, -1.0), vmax = vec(1.0, 1.0, 1.0)),
    material: Material(albedo: vec3(1.0)))
]


var lights = newSeq[Light]()

lights.add(
  DistantLight(color: vec3(1.0), intensity: 9.0,
               dir: vec(-2.0, -0.8, -0.3).normalize)
)
lights.add(
  DistantLight(color: vec3(0.8, 0.3, 0.0), intensity: 2.0,
               dir: vec(2.0, -0.8, -1.3).normalize)
)


var scene = Scene(
  bgColor: vec3(0.15, 0.09, 0.07),

  objects: objects,
  lights: lights,

  fov: 50.0,
  cameraToWorld: mat4(1.0).rotate(X_AXIS, degToRad(-12.0))
                          .translate(vec3(1.0, 5.5, 3.5))
)

