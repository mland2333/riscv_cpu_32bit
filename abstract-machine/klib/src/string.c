#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
  size_t i = 0;
    for(i = 0; *s != '\0'; s++)
        i++;
    i++;
    return i;
}

char *strcpy(char *dst, const char *src) {
    size_t i;
    for(i = 0; src[i] !='\0'; i++)
        dst[i] = src[i];
    dst[i] = '\0';
    return dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
    size_t i;
    for(i = 0; i < n; i++)
        dst[i] = src[i];
    return dst;
}

char *strcat(char *dst, const char *src) {
    char* dst1 = dst;
    while(*dst != '\0')dst++;
    strcpy(dst, src);
    return dst1;
}

int strcmp(const char *s1, const char *s2) {
    int n = 0;
    while(1)
    {
        if(s1[n] < s2[n]) return -1;
        else if(s1[n] > s2[n]) return 1;
        else
        {
            if(s1[n]=='\0') return 0;
            n++;
        }
    }
}

int strncmp(const char *s1, const char *s2, size_t n) {
    int i = 0;
    while(i < n)
    {
        if(s1[i] < s2[i]) return -1;
        else if(s1[i] > s2[i]) return 1;
        else i++;
    }
    return 0;
}

void *memset(void *s, int c, size_t n) {
    const unsigned char uc = c;
    unsigned char *su;
    for(su = s;0 < n;++su,--n)
        *su = uc;
    return s;
}

void *memmove(void *dst, const void *src, size_t n) {
    void* dest = dst;
    if (dst < src) 
    {
    	while (n--)
    	{
    	    *(char*)dst = *(char*)src;
          dst++;
          src++;
    	}
    }
    else 
    {
    	while (n--) 
    	{
    	    *((char*)dst + n) = *((char*)src + n);
    	}

    }
    return dest;
}

void *memcpy(void *out, const void *in, size_t n) {
    return memmove(out, in, n);
}

int memcmp(const void *s1, const void *s2, size_t n) {
    for(int i = 0; i<n; i++)
    {
        if(((char*)s1)[i] < ((char*)s2)[i]) return -1;
        else if(((char*)s1)[i] > ((char*)s2)[i]) return 1;
        
    }
    return 0;
}

#endif
