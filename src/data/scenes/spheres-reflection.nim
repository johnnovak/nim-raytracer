let objects = @[
  Object(
    name: "ball1",
    geometry: initSphere(
      objectToWorld = mat4(1.0).translate(vec3(-5.0, 2.0, -18.0)),
      r = 2),
    material: Material(albedo: vec3(1.0, 1.0, 1.0), reflection: 1.0)
  ),
  Object(
    name: "ball2",
    geometry: initSphere(
      objectToWorld = mat4(1.0).translate(vec3(0.5, 2.0, -8.0)),
      r = 2),
    material: Material(albedo: vec3(1.0, 1.0, 1.0), reflection: 1.0)
  ),
  Object(
    name: "ball3",
    geometry: initSphere(
      objectToWorld = mat4(1.0).translate(vec3(-5.0, 2.0, -10.0)),
      r = 2),
    material: Material(albedo: vec3(1.0, 1.0, 1.0), reflection: 1.0)
  ),
  Object(
    name: "ball4",
    geometry: initSphere(
      objectToWorld = mat4(1.0).translate(vec3(8.0, 2.0, -15.0)),
      r = 2),
    material: Material(albedo: vec3(0.2, 0.3, 0.9), reflection: 0.0)
  ),
  Object(
    name: "ball5",
    geometry: initSphere(
      objectToWorld = mat4(1.0).translate(vec3(4.0, 2.0, -16.0)),
      r = 2),
    material: Material(albedo: vec3(0.2, 0.5, 0.9), reflection: 0.0)
  ),
  Object(
    name: "ball6",
    geometry: initSphere(
      objectToWorld = mat4(1.0).translate(vec3(-2.0, 2.0, -42.0)),
      r = 2),
    material: Material(albedo: vec3(0.9, 0.5, 0.2), reflection: 1.0)
  ),
  Object(
    name: "ball7",
    geometry: initSphere(
      objectToWorld = mat4(1.0).translate(vec3(9.0, 2.0, -30.0)),
      r = 2),
    material: Material(albedo: vec3(0.6, 0.5, 0.9), reflection: 1.0)
  ),
  Object(
    name: "ground",
    geometry: initPlane(objectToWorld = mat4(1.0)),
    material: Material(albedo: vec3(0.4), reflection: 0.0)
  ),
  Object(
    name: "ball-behind1",
    geometry: initSphere(
      objectToWorld = mat4(1.0).translate(vec3(-4.0, 2.0, 0.0)),
      r = 2),
    material: Material(albedo: vec3(0.2, 0.3, 0.6), reflection: 0.0)
  ),
  Object(
    name: "ball-behind2",
    geometry: initSphere(
      objectToWorld = mat4(1.0).translate(vec3(14.0, 2.0, 1.0)),
      r = 2),
    material: Material(albedo: vec3(0.4, 0.8, 1.0), reflection: 0.0)
  )
]


var lights = newSeq[Light]()

lights.add(
  PointLight(color: vec3(1.0, 1.0, 1.0), intensity: 3000.0,
             pos: point(3.0, 6.0, -12.0))
)
lights.add(
  DistantLight(color: vec3(0.3, 0.4, 0.6), intensity: 0.5,
               dir: vec(2.0, -0.8, -1.3).normalize)
)


var scene = Scene(
  bgColor:  vec3(0.25, 0.1, 0.2),

  objects: objects,
  lights: lights,

  fov: 50.0,
  cameraToWorld: mat4(1.0).rotate(X_AXIS, degToRad(-12.0))
                          .translate(vec3(1.0, 5.5, 3.5))
)

