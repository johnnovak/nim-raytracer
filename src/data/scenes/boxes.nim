var objects = newSeq[Object]()

objects.add(
  Object(
    name: "ground",
    geometry: initPlane(objectToWorld = mat4(1.0)),
    material: Material(albedo: vec3(0.4))
  )
)

let ROWS = 4
let PAD = 3.8

let 
  xs = 0.0
  ys = 3.0
  zs = -18.0

var
  x = xs
  y = ys
  z = zs

for i in 0..<ROWS:
  for j in 0..<ROWS:
    for k in 0..<ROWS:
      objects.add(
        Object(
          name: "box",
          geometry: initBox(
            objectToWorld = mat4(1.0).translate(vec3(x, y, z)),
            vmin = vec(-1.3, -1.3, -1.3), vmax = vec(1.3, 1.3, 1.3)),
          material: Material(albedo: vec3(1.0 / ROWS.float * (ROWS-k).float,
                                          1.0 / ROWS.float * (ROWS-j).float,
                                          1.0 / ROWS.float * (ROWS-i).float))
        )
      )

      x += PAD
    y += PAD
    x = xs
  z -= PAD
  x = xs
  y = ys


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
  bgColor: vec3(0.15, 0.09, 0.07),

  objects: objects,
  lights: lights,

  fov: 65.0,
  cameraToWorld: mat4(1.0).rotate(X_AXIS, degToRad(-34.0))
                          .rotate(Y_AXIS, degToRad(-35.0))
                          .translate(vec3(-3.5, 20.5, 9.5))
)

