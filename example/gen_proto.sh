#!/usr/bin/env bash
# protoc-gen-rpc-dispatcher 示例 - 生成代码
#
# 前置条件:
#   1. 安装 protoc
#   2. 安装 protoc-gen-go: go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
#   3. 安装 protoc-gen-rpc-dispatcher: go install github.com/xieweiyu/protoc-gen-rpc-dispatcher@latest
#
# 使用方式:
#   cd example && bash gen_proto.sh

set -euo pipefail

# 获取脚本所在目录，兼容 Git Bash 的 Windows 路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 自动检测 protobuf 的 include 路径
PROTO_INCLUDE=""
PROTOC_DIR=$(dirname "$(which protoc)")/../include
if [ -d "$PROTOC_DIR/google/protobuf" ]; then
  PROTO_INCLUDE="-I=${PROTOC_DIR}"
else
  for dir in /usr/include /usr/local/include /usr/local/opt/protobuf/include /usr/lib/x86_64-linux-gnu/protobuf/include; do
    if [ -d "$dir/google/protobuf" ]; then
      PROTO_INCLUDE="-I=${dir}"
      break
    fi
  done
fi

if [ -z "$PROTO_INCLUDE" ]; then
  if command -v pkg-config &>/dev/null; then
    PC_DIR=$(pkg-config --variable=prefix protobuf 2>/dev/null)/include
    [ -d "$PC_DIR/google/protobuf" ] && PROTO_INCLUDE="-I=${PC_DIR}"
  fi
fi
if [ -z "$PROTO_INCLUDE" ]; then
  if command -v dpkg &>/dev/null; then
    DPKG_DIR=$(dpkg -L protobuf-compiler 2>/dev/null | grep 'include/google/protobuf' | head -1 | sed 's|/google/protobuf.*||')
    [ -n "$DPKG_DIR" ] && PROTO_INCLUDE="-I=${DPKG_DIR}"
  fi
fi

# 切换到脚本目录，之后的路径全用相对路径
cd "$SCRIPT_DIR"

protoc -I=./proto \
  -I="${SCRIPT_DIR}/../proto" \
  ${PROTO_INCLUDE:+"$PROTO_INCLUDE"} \
  --go_out=. --go_opt=module=example \
  --rpc-dispatcher_out=. --rpc-dispatcher_opt=module=example \
  ./proto/*.proto

echo ""
echo "✓ 生成完成!"
echo "生成的文件:"
find . -name "*_dispatcher_gen.go" -o -name "*.pb.go" 2>/dev/null | sort