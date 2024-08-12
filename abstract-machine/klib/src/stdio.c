#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

int printf(const char* fmt, ...)
{
     va_list ap;
     va_start(ap, fmt);
     char *s;
     uint64_t ptr;
     int num;
     uint32_t numx;
     char digits[] = "0123456789abcdef";
     char buf[33];
     int res = 0;
     int j = 0;
     for(int i = 0; fmt[i]!='\0'; i++)
     {
         if(fmt[i] != '%')
         {
             putch(fmt[i]);
             res++;
             continue;
         }
         i++;
         if(fmt[i] == 0) break;
         switch(fmt[i])
         {
             case 's':
                 if((s=va_arg(ap, char*)) == 0)
                     s = "null";
                 for(;*s!=0;s++)
                 {
                     putch(*s);
                     res++;
                 }
                 break;
             case 'p':
                 ptr = va_arg(ap, uint64_t);
                 putch('0');
                 putch('x');
                 res+=2;
                 j = 0;
                 do
                 {
                     buf[j++] = digits[ptr%16];
                     ptr >>= 4;
                     res++;
                 }while(ptr != 0);
                 for(;j>0; j--)
                     putch(buf[j-1]);
                 break;
             case 'd':
                 num = va_arg(ap, int);
                 if(num < 0)
                 {
                     putch('-');
                     num = -num;
                     res++;
                 }
                 j = 0;
                 do
                 {
                     buf[j++] = digits[num%10];
                     num /= 10;
                     res++;
                 }while(num != 0);
                 for(;j>0; j--)
                     putch(buf[j-1]);
                 break;
             case 'x':
                 numx = va_arg(ap, uint32_t);
                 
                 putch('0');
                 putch('x');
                 res+=2;
                 j = 0;
                 do
                 {
                     buf[j++] = digits[numx%16];
                     numx >>= 4;
                     res++;
                 }while(numx != 0);
                 for(;j>0; j--)
                     putch(buf[j-1]);
                 break;

         }
     }
     return res;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  panic("Not implemented");
}

int sprintf(char *out, const char *fmt, ...) {
     va_list ap;
     va_start(ap, fmt);
     char *s;
     uint64_t ptr;
     int num;
     char digits[] = "0123456789abcdef";
     char buf[33];
     int res = 0;
     int j = 0;
     for(int i = 0; fmt[i]!='\0'; i++)
     {
         if(fmt[i] != '%')
         {
             out[res++] = fmt[i];
             continue;
         }
         i++;
         if(fmt[i] == 0) break;
         switch(fmt[i])
         {
             case 's':
                 if((s=va_arg(ap, char*)) == 0)
                     s = "null";
                 for(;*s!=0;s++)
                 {
                     out[res++] = *s;
                 }
                 break;
             case 'p':
                 ptr = va_arg(ap, uint64_t);
                 out[res++] = '0';
                 out[res++] = 'x';
                 
                 j = 0;
                 do
                 {
                     buf[j++] = digits[ptr%16];
                     ptr >>= 4;
                 }while(ptr != 0);
                 for(;j>0; j--)
                     out[res++] = buf[j - 1];
                 break;
             case 'd':
                 num = va_arg(ap, int);
                 if(num < 0)
                 {
                     out[res++] = '-';
                     num = -num;
                 }
                 j = 0;
                 do
                 {
                     buf[j++] = digits[num%10];
                     num /= 10;
                 }while(num != 0);
                 for(;j>0; j--)
                     out[res++] = buf[j - 1];
                 break;
             case 'x':
                 num = va_arg(ap, int);
                 if(num < 0)
                 {
                     out[res++] = '-';
                     num = -num;
                 }
                 out[res++] = '0';
                 out[res++] = 'x';
                 j = 0;
                 do
                 {
                     buf[j++] = digits[num%16];
                     num >>= 4;
                     //res++;
                 }while(num != 0);
                 for(;j>0; j--)
                     out[res++] = buf[j - 1];
                 break;
         }
     }
     out[res] = 0;
     va_end(ap);
  return res;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
