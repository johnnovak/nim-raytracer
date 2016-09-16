let objects = @[
  Sphere(o: point(-5.0, 0.0, -15.0),
         r: 2,
         albedo: vec3(0.9, 0.3, 0.2)),

  Sphere(o: point(-1.0, 0.0, -10.0),
         r: 2,
         albedo: vec3(0.3, 0.9, 0.2)),

  Sphere(o: point(5.0, 0.0, -15.0),
         r: 2,
         albedo: vec3(0.2, 0.3, 0.9)),

  Sphere(o: point(0.0, 0.0, -38.0),
         r: 2,
         albedo: vec3(0.9, 0.8, 0.2)),

  Sphere(o: point(6.0, 0.0, -30.0),
         r: 2,
         albedo: vec3(0.6, 0.5, 0.9)),

  Plane(o: point(0.0, -2.0, 0.0),
        n: vec(0.0, 1.0, 0.0),
        albedo: vec3(1.0, 1.0, 1.0))
]

var scene = Scene(
  objects: objects
)
