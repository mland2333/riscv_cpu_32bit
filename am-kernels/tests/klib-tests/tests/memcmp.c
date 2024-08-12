#include "trap.h"

int main()
{
    char *s = "hello world\n";
    char *s1 = "hello\n";
    check(memcmp(s, s, 12) == 0);
    check(memcmp(s, s1, 6) == 1);
    check(memcmp(s1, s, 6) == -1);
    return 0;
}
