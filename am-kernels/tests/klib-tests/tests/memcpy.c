#include "trap.h"


#define N 14


int main()
{
    char str[N] = "hello world!\n";
    char str2[N];
    //printf("%s", str);
    //putstr(str);
    memcpy(str2, str, N);
    for(int i = 0 ; i<N; i++)
        check(str[i]==str2[i]);
    return 0;
}
