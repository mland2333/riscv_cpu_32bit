#include "trap.h"

int main()
{
    char *s = "hello 10 0x10\n";
    char str[14];
    sprintf(str, "%s %d %x\n", "hello", 10, 16);
    //printf("%s", str);
    //check(n == 13);
    
    check(strcmp(s, str) == 0);
    return 0;
}
