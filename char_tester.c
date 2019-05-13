#include <stdio.h>

int main(){
    int c = getc(stdin);
    printf("%d", c);
    ungetc(c, stdin);
    return 0;
}