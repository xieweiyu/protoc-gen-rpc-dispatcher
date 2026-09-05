#!/usr/bin/env bash
# protoc-gen-rpc-dispatcher 示例 - 生成代码
#
# 前置条件:
#   1. 安装 protoc
#   2. 安装 protoc-gen-go: go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
#   3. 安装 protoc-gen-rpc-dispatcher: go install github.com/xieweiyu/protoc-gen-rpc-dispatcher@latest
#
# 为什么循环而不是 *.proto:
#   protoc-gen-micro 一次处理多个文件时要求所有 go_package 路径前缀一致，
#   否则报 inconsistent package import paths 错误。
#   所以每个 proto 文件单独生成，互不影响。
#
# 使用方式:
#   cd example && bash gen_proto.sh

set -euo pipefail

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 公共 proto 路径（gen-dispatcher.proto 所在目录）
DISPATCHER_PROTO="${SCRIPT_DIR}/../proto"

for proto in ./proto/*.proto; do
  echo "── 生成 ${proto} ..."

  # 判断是否包含 service（只有包含 service 才需要 micro/dispatcher）
  if grep -q "^service " "${proto}"; then
    protoc -I=./proto \
      -I="${DISPATCHER_PROTO}" \
      --go_out=. --go_opt=module=example \
      --micro_out=. --micro_opt=module=example \
      --rpc-dispatcher_out=. --rpc-dispatcher_opt=module=example \
      "${proto}"
  else
    # 无 service 的文件只需要 go 代码
    protoc -I=./proto \
      -I="${DISPATCHER_PROTO}" \
      --go_out=. --go_opt=module=example \
      "${proto}"
  fi
done

echo ""
echo "✓ 生成完成!"
echo "生成的文件:"
find . -name "*_dispatcher_gen.go" -o -name "*.pb.go" -o -name "*.pb.micro.go" 2>/dev/null | sort