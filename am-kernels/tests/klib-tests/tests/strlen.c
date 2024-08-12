#include "trap.h"

int main()
{
    char *s = "hello world\n";
    int n = strlen(s);
    check(n==13);
    return 0;
}
