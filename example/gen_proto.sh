#!/usr/bin/env bash
# protoc-gen-rpc-dispatcher 示例 - 生成代码
#
# 前置条件:
#   1. 安装 protoc
#   2. 安装 protoc-gen-go: go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
#   3. 安装 protoc-gen-micro: go install github.com/go-micro/generator/cmd/protoc-gen-micro@latest
#   4. 安装 protoc-gen-rpc-dispatcher: go install github.com/xieweiyu/protoc-gen-rpc-dispatcher@latest
#
# 路径说明:
#   --go_out / --rpc-dispatcher_out: 用 module=example 模式，输出到 example 目录
#   --micro_out: 不带任何 opt，指向项目根，protoc-gen-micro v1.0.0 会用 go_package 路径
#
# 使用方式:
#   cd example && bash gen_proto.sh

set -euo pipefail

# 获取脚本所在目录（example/）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 项目根目录（example 的上一级）
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 公共 proto 路径（gen-dispatcher.proto 所在目录）
DISPATCHER_PROTO="${PROJECT_ROOT}/proto"

for proto in ./proto/*.proto; do
  echo "── 生成 ${proto} ..."

  # 判断是否包含 service（只有包含 service 才需要 micro/dispatcher）
  if grep -q "^service " "${proto}"; then
    protoc -I=./proto \
      -I="${DISPATCHER_PROTO}" \
      --go_out="${SCRIPT_DIR}" --go_opt=module=example \
      --micro_out="${PROJECT_ROOT}" \
      --rpc-dispatcher_out="${SCRIPT_DIR}" --rpc-dispatcher_opt=module=example \
      "${proto}"
  else
    # 无 service 的文件只需要 go 代码
    protoc -I=./proto \
      -I="${DISPATCHER_PROTO}" \
      --go_out="${SCRIPT_DIR}" --go_opt=module=example \
      "${proto}"
  fi
done


# 获取脚本所在目录（example/）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 项目根目录（example 的上一级）
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo ""
echo "✓ 生成完成!"
echo "生成的文件:"
find "${PROJECT_ROOT}" -name "*_dispatcher_gen.go" -o -name "*.pb.go" -o -name "*.pb.micro.go" 2>/dev/null | sort