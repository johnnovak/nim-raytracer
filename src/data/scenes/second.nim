let objects = @[
  Sphere(o: point(-5.0, 2.0, -18.0),
         r: 2,
         albedo: vec3(0.9, 0.3, 0.2)),

  Sphere(o: point(0.5, 2.0, -8.0),
         r: 2,
         albedo: vec3(0.6, 0.9, 0.2)),

  Sphere(o: point(-5.0, 2.0, -10.0),
         r: 2,
         albedo: vec3(0.1, 0.7, 0.2)),

  Sphere(o: point(8.0, 2.0, -15.0),
         r: 2,
         albedo: vec3(0.2, 0.3, 0.9)),

  Sphere(o: point(4.0, 2.0, -16.0),
         r: 2,
         albedo: vec3(0.2, 0.5, 0.9)),

  Sphere(o: point(-2.0, 2.0, -42.0),
         r: 2,
         albedo: vec3(0.9, 0.5, 0.2)),

  Sphere(o: point(9.0, 2.0, -30.0),
         r: 2,
         albedo: vec3(0.6, 0.5, 0.9)),

  Plane(o: point(0.0, 0.0, 0.0),
        n: vec(0.0, 1.0, 0.0),
        albedo: vec3(0.4))
]

var lights = newSeq[Light]()

lights.add(
  DistantLight(color: vec3(1.0, 0.0, 0.0), intensity: 4.5,
               dir: vec(1.7, -0.5, 2.3).normalize)
)

lights.add(
  DistantLight(color: vec3(1.0, 0.0, 1.0), intensity: 1.5,
               dir: vec(-2.7, -0.5, 2.3).normalize)
)

let bgColor = vec3(0.30, 0.00, 0.02)


#lights.add(
#  DistantLight(color: vec3(1.0), intensity: 1.5,
#               dir: vec(-2.0, -0.8, -0.3).normalize)
#)
#
#lights.add(
#  DistantLight(color: vec3(0.8, 0.3, 0.0), intensity: 0.8,
#               dir: vec(2.0, -0.8, -1.3).normalize)
#)

#let bgColor = vec3(0.01, 0.03, 0.05)


#lights.add(
#  DistantLight(color: vec3(1.0), intensity: 0.2,
#               dir: vec(-2.0, -0.8, -0.3).normalize)
#)
#
#lights.add(
#  DistantLight(color: vec3(0.1, 0.6, 0.8), intensity: 8.0,
#               dir: vec(0.5, -0.4,  0.8).normalize)
#)
#
#let bgColor = vec3(0.1, 0.6, 0.8)


var scene = Scene(
  objects: objects,
  lights: lights,
  fov: 50.0,
  cameraToWorld: mat4(1.0).rotate(vec3(1.0, 0, 0), degToRad(-12.0))
                          .translate(vec3(1.0, 5.5, 3.5)),
  bgColor: bgColor
)
