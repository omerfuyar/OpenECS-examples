// A sample of C for the viewer
#include <stdio.h>

#define GREETING "Hello"

typedef struct Point
{
    int x;
    float y;
} Point;

int main(void)
{
    Point point = {3, 4.5f};
    printf("%s, %d\n", GREETING, point.x);
    return 0;
}
