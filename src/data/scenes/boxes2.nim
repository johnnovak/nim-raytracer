var objects = newSeq[Object]()

objects.add(
  Object(
    name: "ball1",
    geometry: initSphere(
      objectToWorld = mat4(1.0).translate(vec3(0.0, 1.5, -18.0)),
      r = 1.5),
    material: Material(albedo: vec3(0.5))
  )
)

objects.add(
  Object(
    name: "ground",
    geometry: initPlane(objectToWorld = mat4(1.0)),
    material: Material(albedo: vec3(0.3))
  )
)

let N = 12
var rot = 0.0

for i in 0..<N:
  objects.add(
    Object(
      name: "box",
      geometry: initBox(
        objectToWorld = mat4(1.0).translate(vec3(0.0, 0.5, -18.0))
                                 .rotate(Y_AXIS, degToRad(rot))
                                 .translate(vec3(0.0, 0.0, 5.0)),
        vmin = vec(-0.5, -0.5, -0.5), vmax = vec(0.5, 0.5, 0.5)),
      material: Material(albedo: vec3(0.5))
    )
  )
  rot += 360.0 / N.float


var lights = newSeq[Light]()

lights.add(
  PointLight(color: vec3(1.0, 0.8, 0.5), intensity: 4000.0,
               pos: point(2.0, 8.0, -25.0))
)
lights.add(
  DistantLight(color: vec3(1.0, 0.0, 0.0), intensity: 3.0,
               dir: vec(1.7, -0.5, 2.3).normalize)
)
lights.add(
  DistantLight(color: vec3(1.0, 0.0, 0.0), intensity: 0.3,
               dir: vec(-6.0, -0.5, -2.3).normalize)
)


var scene = Scene(
  bgColor: vec3(0.15, 0.07, 0.04),

  objects: objects,
  lights: lights,

  fov: 50.0,
  cameraToWorld: mat4(1.0).rotate(X_AXIS, degToRad(-15.0))
                          .translate(vec3(0.0, 4.8, -4.5))
)

