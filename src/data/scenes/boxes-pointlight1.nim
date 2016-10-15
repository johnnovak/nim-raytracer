let objects = @[
  Object(
    name: "box-red",
    geometry: initBox(
      objectToWorld = mat4(1.0).translate(vec3(-5.0, 2.0, -18.0))
                               .rotate(X_AXIS, degToRad(-10.0)),
      vmin = vec(-1.0, -1.0, -1.0), vmax = vec(1.0, 1.0, 1.0)),
    material: Material(albedo: vec3(0.9, 0.3, 0.2))
  ),
  Object(
    name: "box-yellow",
    geometry: initBox(
      objectToWorld = mat4(1.0).translate(vec3(0.5, 2.0, -6.0))
                               .rotate(X_AXIS, degToRad(-50.0)),
      vmin = vec(-1.0, -1.0, -1.0), vmax = vec(1.0, 1.0, 1.0)),
    material: Material(albedo: vec3(0.6, 0.9, 0.2))
  ),
  Object(
    name: "box3",
    geometry: initBox(
      objectToWorld = mat4(1.0).translate(vec3(-5.0, 2.0, -10.0))
                               .rotate(X_AXIS, degToRad(-50.0)),
      vmin = vec(-1.0, -1.0, -1.0), vmax = vec(1.0, 1.0, 1.0)),
    material: Material(albedo: vec3(0.1, 0.7, 0.2))
  ),
  Object(
    name: "box4",
    geometry: initBox(
      objectToWorld = mat4(1.0).translate(vec3(8.0, 2.0, -15.0))
                               .rotate(X_AXIS, degToRad(-70.0)),
      vmin = vec(-1.0, -1.0, -1.0), vmax = vec(1.0, 1.0, 1.0)),
    material: Material(albedo: vec3(0.2, 0.3, 0.9))
  ),
  Object(
    name: "box5",
    geometry: initBox(
      objectToWorld = mat4(1.0).translate(vec3(4.0, 2.0, -16.0))
                               .rotate(X_AXIS, degToRad(-60.0)),
      vmin = vec(-1.0, -1.0, -1.0), vmax = vec(1.0, 1.0, 1.0)),
    material: Material(albedo: vec3(0.2, 0.5, 0.9))
  ),
  Object(
    name: "box6",
    geometry: initBox(
      objectToWorld = mat4(1.0).translate(vec3(-2.0, 2.0, -52.0))
                               .rotate(X_AXIS, degToRad(-40.0)),
      vmin = vec(-1.0, -1.0, -1.0), vmax = vec(1.0, 1.0, 1.0)),
    material: Material(albedo: vec3(0.9, 0.5, 0.2))
  ),
  Object(
    name: "box7",
    geometry: initBox(
      objectToWorld = mat4(1.0).translate(vec3(9.0, 2.0, -30.0))
                               .rotate(X_AXIS, degToRad(-20.0)),
      vmin = vec(-1.0, -1.0, -1.0), vmax = vec(1.0, 1.0, 1.0)),
    material: Material(albedo: vec3(0.6, 0.5, 0.9))
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
  bgColor: vec3(0.6, 0.6, 0.5),

  objects: objects,
  lights: lights,

  fov: 50.0,
  cameraToWorld: mat4(1.0).rotate(X_AXIS, degToRad(-12.0))
                          .translate(vec3(0.5, 5.5, 3.5))
)

