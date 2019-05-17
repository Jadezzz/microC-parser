// void foo(int a, int b){
//     int c = 10;
//     c = a + b / 10;
//     b++;
// }

// int main(){

//     float k;
//     int d;
//     if(d == 10){
//         float d = 100;
//         int e = 100;
//         e = d + 20;
//     } else if (d == 9) {
//         string k = "HI";
//         print(k);
//     } else if (d == 8) {
//         print(d);
//     } else {
//         print("Nothing");
//         fooooo(d, k){

        
//     }
//     return 0;
// }

void foo1(int a, int b);
int global = 10;
int foo(){
    int b;
    if(global > 10){
        int a = 10;
    } 
    else if (global > 8) {
        int a = 8;
    }
    else {
        int a = 7;
    }
    return b;
}


int main(){
    int m;
    int n;
    foo();
    foo1(m, n);
    return 0;
}

void foo1(int a, int b){
    while(a > 0){
        b += 1;
        a--;
    }
    return b;
}

