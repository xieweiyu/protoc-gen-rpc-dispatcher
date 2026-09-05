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

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 自动检测 protobuf 的 include 路径
PROTO_INCLUDE=""
PROTOC_DIR=$(dirname "$(which protoc)")/../include
if [ -d "$PROTOC_DIR/google/protobuf" ]; then
  PROTO_INCLUDE="-I=${PROTOC_DIR}"
else
  for dir in /usr/include /usr/local/include /usr/local/opt/protobuf/include; do
    if [ -d "$dir/google/protobuf" ]; then
      PROTO_INCLUDE="-I=${dir}"
      break
    fi
  done
fi

# 公共 proto 路径（gen-dispatcher.proto 所在目录）
DISPATCHER_PROTO="${SCRIPT_DIR}/../proto"

# 先生成 common.proto（只有 --go_out，没有 service 不需要 micro/dispatcher）
protoc -I=./proto \
  -I="${DISPATCHER_PROTO}" \
  ${PROTO_INCLUDE:+"$PROTO_INCLUDE"} \
  --go_out=. --go_opt=module=example \
  ./proto/common.proto

# 再生成 user.proto（包含所有插件）
protoc -I=./proto \
  -I="${DISPATCHER_PROTO}" \
  ${PROTO_INCLUDE:+"$PROTO_INCLUDE"} \
  --go_out=. --go_opt=module=example \
  --micro_out=. --micro_opt=module=example \
  --rpc-dispatcher_out=. --rpc-dispatcher_opt=module=example \
  ./proto/user.proto

echo ""
echo "✓ 生成完成!"
echo "生成的文件:"
find . -name "*_dispatcher_gen.go" -o -name "*.pb.go" -o -name "*.pb.micro.go" 2>/dev/null | sort