// gcc -std=c++11 -lm -O3 -o cgeomtest geomtest.cpp

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <time.h>


struct Vec3
{
  double x;
  double y;
  double z;
};

struct Ray
{
  Vec3 orig;
  Vec3 dir;
};

Vec3 sub(Vec3 a, Vec3 b)
{
  return {a.x - b.x, a.y - b.y, a.z - b.z};
}

double dot(Vec3 a, Vec3 b)
{
  return a.x * b.x + a.y * b.y + a.z * b.z;
}

Vec3 cross(Vec3 a, Vec3 b)
{
  return {
    a.y * b.z - a.z * b.y,
    a.z * b.x - a.x * b.z,
    a.x * b.y - a.y * b.x
  };
}

void printVec3(Vec3 *v)
{
//    printf("[%f, %f, %f]", v->x, v->y, v->z);
}

double rayTriangleIntersect(Ray *r, Vec3 *v0, Vec3 *v1, Vec3 *v2)
{
  Vec3 v0v1 = sub(*v1, *v0);
//  printf("v0v1: ");
//  printVec3(&v0v1);

  Vec3 v0v2 = sub(*v2, *v0);
//  printf("\nv0v2: ");
//  printVec3(&v0v2);

  Vec3 pvec = cross(r->dir, v0v2);
//  printf("\npvec: ");
//  printVec3(&pvec);

  double det = dot(v0v1, pvec);
//  printf("\ndet: %f", det);

  if (det < 0.000001)
    return -INFINITY;

  double invDet = 1.0 / det;
//  printf("\ninvDet: %f", invDet);

  Vec3 tvec = sub(r->orig, *v0);
//  printf("\ntvec: ");
//  printVec3(&tvec);

  double u = dot(tvec, pvec) * invDet;
//  printf("\nu: %f", u);

  if (u < 0 || u > 1)
    return -INFINITY;

  Vec3 qvec = cross(tvec, v0v1);
//  printf("\nqvec: ");
//  printVec3(&qvec);

  double v = dot(r->dir, qvec) * invDet;
//  printf("\nv: %f", v);

  if (v < 0 || u + v > 1)
    return -INFINITY;

  return dot(v0v2, qvec) * invDet;
}

long ellapsedMs(struct timeval t0, struct timeval t1)
{
  return 1000 * (t1.tv_sec - t0.tv_sec) + (t1.tv_usec - t0.tv_usec) / 1000;
}

Vec3 randomSphere() {
  double r1 = (double) rand() / RAND_MAX;
  double r2 = (double) rand() / RAND_MAX;
  double lat = acos(2*r1 - 1) - M_PI/2;
  double lon = 2*M_PI * r2;

  return {cos(lat) * cos(lon),
          cos(lat) * sin(lon),
          sin(lat)};
}

const int NUM_RAYS = 100000;

int main()
{
  srand(time(NULL));


  Ray r;
  r.dir  = { 0.0, 0.0, -1.0 };

  Vec3 v1 = { -2.0, -1.0, -5.0 };
  Vec3 v2 = {  2.0, -1.0, -5.0 };
  Vec3 v3 = {  0.0,  1.0, -5.0 };

  int N = 10000123;
  float t = 0.0;

  struct timeval tStart;
  gettimeofday(&tStart, 0);

  for (int i = 0; i < N; ++i)
  {
    r.orig = { 0.0, 0.0, 0.0 };
    t += rayTriangleIntersect(&r, &v1, &v2, &v3);
  }

  struct timeval tEnd;
  gettimeofday(&tEnd, 0);

  double tTotal = (float) ellapsedMs(tStart, tEnd) / 1000.0f;

  printf("%f\n", t);

  printf("Total time: %f\n", tTotal);
  printf("Millions of intersection tests per second: %f\n",
         ((float) N) / tTotal / 1000000.0);
}


