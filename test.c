// Forward Declaration Test, No ERROR
int foo(int a, int b);

int foo(int foo, int b){

}

// Redeclaraion, ERROR
int foo1(int a);

int foo1(float a);


int main(){

    int a;
    float b;
    bool c;
    string d;


    if(a == b){
        int kk = 0;
    }  else if( c == d){
        string dd = "jsjs";
    } else{
        print(e);
    }

    c = foo1(a,b);
}



