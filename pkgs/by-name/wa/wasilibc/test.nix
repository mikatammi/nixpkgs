{
  runCommandCC,
  wasmtime,
}:

# A quicker way than building firefox to see whether compiling and linking
# against wasilibc works, both for C and C++ (libc++).
runCommandCC "wasilibc-simple-c-cxx-binaries"
  {
    __structuredAttrs = true;
    strictDeps = true;
    nativeBuildInputs = [ wasmtime ];
  }
  ''
    cat > test.c <<EOF
    #include <stdio.h>
    int main(void) {
      puts("Hello from C");
      return 0;
    }
    EOF
    cat > test.cpp <<EOF
    #include <iostream>
    int main(void) {
      std::cout << "Hello from C++" << std::endl;
      return 0;
    }
    EOF

    mkdir -p "$out/bin"
    $CC -o "$out/bin/test-c" test.c
    $CXX -o "$out/bin/test-cxx" test.cpp

    export HOME=$TMPDIR
    [ "$(wasmtime run "$out/bin/test-c")" = "Hello from C" ]
    [ "$(wasmtime run "$out/bin/test-cxx")" = "Hello from C++" ]
  ''
