#!/usr/bin/env bash
set -euxo pipefail

cat > smoke.mojo <<'EOF'
from tracy import frame_mark, is_connected, message, set_thread_name, Zone

def foo():
    with Zone("foo"):
        bar()

def bar():
    with Zone().scoped[bar]():
        pass

def main() raises:
    set_thread_name("mojo-tracy rattler-build smoke")
    message("hello from mojo-tracy package")
    frame_mark()
    foo()
    print("connected:", is_connected())
EOF

mojo run \
    -Xlinker -L"lib" \
    -Xlinker -lmojotracy \
    smoke.mojo
