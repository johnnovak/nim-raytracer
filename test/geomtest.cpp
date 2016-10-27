// gcc -std=c++11 -lm -O3 -o cgeomtest geomtest.cpp

#include <stdio.h>
#include <math.h>

#define min(a,b) ((a) < (b) ? (a) : (b))
#define max(a,b) ((a) > (b) ? (a) : (b))


union Vector
{
  struct
  {
    double x;
    double y;
    double z;
  };
  double xyz[3];
};

struct Ray
{
  Vector orig;
  Vector dir;
  Vector invDir;
  int    sign[3];
};

void Init(Ray* r, Vector orig, Vector dir)
{
  r->orig = orig;
  r->dir = dir;

  r->invDir = {1.0 / r->dir.x, 1.0 / r->dir.y, 1.0 / r->dir.z};

  r->sign[0] = r->invDir.x < 0;
  r->sign[1] = r->invDir.y < 0;
  r->sign[2] = r->invDir.z < 0;
}


struct AABB
{
  Vector bounds[2];
};

void Init(AABB* b, Vector vmin, Vector vmax)
{
  b->bounds[0] = vmin;
  b->bounds[1] = vmax;
}


double intersect(AABB *b, Ray *r)
{
  double tmin = -INFINITY;
  double tmax = INFINITY;

  double txmin = (b->bounds[    r->sign[0]].x - r->orig.x) * r->invDir.x;
  double txmax = (b->bounds[1 - r->sign[0]].x - r->orig.x) * r->invDir.x;
  double tymin = (b->bounds[    r->sign[1]].y - r->orig.y) * r->invDir.y;
  double tymax = (b->bounds[1 - r->sign[1]].y - r->orig.y) * r->invDir.y;
  double tzmin = (b->bounds[    r->sign[2]].z - r->orig.z) * r->invDir.z;
  double tzmax = (b->bounds[1 - r->sign[2]].z - r->orig.z) * r->invDir.z;

  tmin = max(tzmin, max(tymin, max(txmin, tmin)));
  tmax = min(tzmax, min(tymax, min(txmax, tmax)));
  tmax *= 1.0000000000000004;

  if (tmin <= tmax)
  {
    return tmin;
  }
  else
  {
    return -INFINITY;
  }
}


int main()
{
  Ray ray;
  Init(&ray, {0.0, 0.0, 0.0}, {0.1, 0.2, -0.8});

  AABB box;
  Init(&box, {-1.0, -1.0, -1.0}, { 1.0,  1.0,  1.0});

  float t = 0.0;

  for (int i = 0; i < 100000000; ++i)
  {
    t += intersect(&box, &ray);
  }

  printf("%f", t);
}
