/*
type
  Ray* = ref object
    orig*, dir*: Vec4[float]   # origin and normalized direction vector
    depth*: int                # ray depth (number of recursions)
    invDir*: Vec3[float]       # 1/dir

proc initRay*(orig, dir: Vec4[float], depth: int = 1): Ray =
  result = Ray(orig: orig, dir: dir,
               invDir: vec3(1/dir.x, 1/dir.y, 1/dir.z))


type
  AABB* = ref object
    vmin, vmax: Vec4[float]



float intersect(b: AABB, r: Ray): float =
  var tmin, tmax: float
  if r.invdir.x >= 0:
    tmin = (b.vmin.x - r.orig.x) * r.invdir.x
    tmax = (b.vmax.x - r.orig.x) * r.invdir.x
  else:
    tmin = (b.vmax.x - r.orig.x) * r.invdir.x
    tmax = (b.vmin.x - r.orig.x) * r.invdir.x

  var tymin, tymax: float
  if r.invdir.y >= 0:
    tymin = (b.vmin.y - r.orig.y) * r.invdir.y
    tymax = (b.vmax.y - r.orig.y) * r.invdir.y
  else:
    tymin = (b.vmax.y - r.orig.y) * r.invdir.y
    tymax = (b.vmin.y - r.orig.y) * r.invdir.y

  if (tmin > tymax) or (tymin > tmax): return -Inf

  if tymin > tmin: tmin = tymin
  if tymax < tmax: tmax = tymax

  var tzmin, tzmax: float
  if r.invdir.z >= 0:
    tzmin = (b.vmin.z - r.orig.z) * r.invdir.z
    tzmax = (b.vmax.z - r.orig.z) * r.invdir.z
  else:
    tzmin = (b.vmax.z - r.orig.z) * r.invdir.z
    tzmax = (b.vmin.z - r.orig.z) * r.invdir.z

  if tmin > tzmax or tzmin > tmax: return -Inf

  if tzmin > tmin: tmin = tzmin
  if tzmax < tmax: tmax = tzmax

  return tmin

*/

#include <stdio.h>
#include <math.h>
#include <time.h>

struct Point {
    double x, y, z;
};

struct Ray {
    struct Point    orig;
    struct Point    dir;
    struct Point    invdir;
};

struct AABB {
    struct Point    vmin;
    struct Point    vmax;
};


double intersect(struct AABB b, struct Ray r) {
  double tmin, tmax;
  if (r.invdir.x >= 0) {
    tmin = (b.vmin.x - r.orig.x) * r.invdir.x;
    tmax = (b.vmax.x - r.orig.x) * r.invdir.x;
  } else {
    tmin = (b.vmax.x - r.orig.x) * r.invdir.x;
    tmax = (b.vmin.x - r.orig.x) * r.invdir.x;
  }

  double tymin, tymax;
  if (r.invdir.y >= 0) {
    tymin = (b.vmin.y - r.orig.y) * r.invdir.y;
    tymax = (b.vmax.y - r.orig.y) * r.invdir.y;
  } else {
    tymin = (b.vmax.y - r.orig.y) * r.invdir.y;
    tymax = (b.vmin.y - r.orig.y) * r.invdir.y;
  }

  if ((tmin > tymax) || (tymin > tmax)) {
      return -INFINITY;
  }

  if (tymin > tmin) tmin = tymin;
  if (tymax < tmax) tmax = tymax;

  double tzmin, tzmax;
  if (r.invdir.z >= 0) {
    tzmin = (b.vmin.z - r.orig.z) * r.invdir.z;
    tzmax = (b.vmax.z - r.orig.z) * r.invdir.z;
  } else {
    tzmin = (b.vmax.z - r.orig.z) * r.invdir.z;
    tzmax = (b.vmin.z - r.orig.z) * r.invdir.z;
  }

  if (tmin > tzmax || tzmin > tmax) {
      return -INFINITY;
  }

  if (tzmin > tmin) tmin = tzmin;
  if (tzmax < tmax) tmax = tzmax;

  return tmin;
}

main() {
    long n = 100000000;

    struct AABB b;
    b.vmin = (struct Point) {-1.0, -1.0, -1.0};
    b.vmax = (struct Point) {1.0, 1.0, 1.0};

    struct Ray r;
    r.orig = (struct Point) {0.0, 0.0, 2.0};
    r.dir = (struct Point) {0.3, 0.4, -1.0};
    r.invdir = (struct Point) {1/r.dir.x, 1/r.dir.y, 1/r.dir.z};

    clock_t start, end;
    start = clock();

    double res;
    int i;
    for (i = 0; i < n; i++) {
      res += intersect(b, r);
    }
    printf("%f", res);

    end = clock();
    clock_t total = (end - start)/(double)CLOCKS_PER_SEC;

    printf("Total time: %f s\n", total); 
    printf("Millions of intersections per second: %f\n", (double)n / total / 1000000);
}
