const Z_DIST = -18.0

var objects = @[

  Object(
    name: "ground",
    geometry: initPlane(objectToWorld = mat4(1.0)),
    material: Material(albedo: vec3(0.3))
  ),
  Object(
    name: "platform",
    geometry: initBox(
      objectToWorld = mat4(1.0).translate(vec3(0.0, 0.0, Z_DIST)),
      vmin = vec(-6.3, 0.0, -6.3), vmax = vec(6.3, 0.5, 6.3)),
    material: Material(albedo: vec3(0.5))
  ),
  Object(
    name: "ball",
    geometry: initSphere(
      objectToWorld = mat4(1.0).translate(vec3(0.0, 4.8, Z_DIST)),
      r = 1.5),
    material: Material(albedo: vec3(0.5))
  )
]

let N = 13
var rot = 0.0

for i in 0..<N:
  objects.add(
    Object(
      name: "box" & $i,
      geometry: initBox(
        objectToWorld = mat4(1.0).translate(vec3(0.0, 1.0, Z_DIST))
                                 .rotate(Y_AXIS, degToRad(rot))
                                 .translate(vec3(0.0, 0.0, 5.0)),
        vmin = vec(-0.5, -0.5, -0.5), vmax = vec(0.5, 0.5, 0.5)),
      material: Material(albedo: vec3(0.5))
    )
  )
  rot += 360.0 / N.float


var lights = newSeq[Light]()

lights.add(
  DistantLight(color: vec3(1.0, 1.0, 1.0), intensity: 0.5,
               dir: vec(3.0, -0.5, -4.0).normalize)
)


var scene = Scene(
  bgColor: vec3(0.15, 0.07, 0.04),

  objects: objects,
  lights: lights,

  fov: 20.0,
  cameraToWorld: mat4(1.0).rotate(X_AXIS, degToRad(-15.0))
                          .translate(vec3(0.0, 6.0, 20.0))
)

