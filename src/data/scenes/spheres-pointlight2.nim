let objects = @[
  Object(
    name: "ball1",
    geometry: Sphere(o: point(-5.0, 2.0, -18.0), r: 2),
    material: Material(albedo: vec3(0.9, 0.3, 0.2))
  ),
  Object(
    name: "ball2",
    geometry: Sphere(o: point(0.5, 2.0, -8.0), r: 2),
    material: Material(albedo: vec3(0.6, 0.9, 0.2))
  ),
  Object(
    name: "ball3",
    geometry: Sphere(o: point(-5.0, 2.0, -10.0), r: 2),
    material: Material(albedo: vec3(0.1, 0.7, 0.2))
  ),
  Object(
    name: "ball4",
    geometry: Sphere(o: point(8.0, 2.0, -15.0), r: 2),
    material: Material(albedo: vec3(0.2, 0.3, 0.9))
  ),
  Object(
    name: "ball5",
    geometry: Sphere(o: point(4.0, 2.0, -16.0), r: 2),
    material: Material(albedo: vec3(0.2, 0.5, 0.9))
  ),
  Object(
    name: "ball6",
    geometry: Sphere(o: point(-2.0, 2.0, -42.0), r: 2),
    material: Material(albedo: vec3(0.9, 0.5, 0.2))
  ),
  Object(
    name: "ball7",
    geometry: Sphere(o: point(9.0, 2.0, -30.0), r: 2),
    material: Material(albedo: vec3(0.6, 0.5, 0.9))
  ),
  Object(
    name: "ground",
    geometry: Plane(o: point(0.0, 0.0, 0.0), n: vec(0.0, 1.0, 0.0)),
    material: Material(albedo: vec3(0.4))
  )
]


var lights = newSeq[Light]()

lights.add(
  PointLight(color: vec3(1.0, 0.8, 0.5), intensity: 5000.0,
               pos: vec(0.0, 8.0, -35.0))
)


var scene = Scene(
  bgColor:  vec3(0.0, 0.0, 0.0),

  objects: objects,
  lights: lights,

  fov: 50.0,
  cameraToWorld: mat4(1.0).rotate(vec3(1.0, 0, 0), degToRad(-12.0))
                          .translate(vec3(1.0, 5.5, 3.5))
)

