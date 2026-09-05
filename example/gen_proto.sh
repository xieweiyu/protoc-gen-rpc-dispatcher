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

# 公共 proto 路径（gen-dispatcher.proto 所在目录）
DISPATCHER_PROTO="${SCRIPT_DIR}/../proto"

# 逐个生成每个 proto 文件
# - 没有 service 的 proto（如 common.proto）micro/dispatcher 插件会自动跳过
for proto in ./proto/*.proto; do
  echo "── 生成 ${proto} ..."
  protoc -I=./proto \
    -I="${DISPATCHER_PROTO}" \
    --go_out=. --go_opt=module=example \
    --micro_out=. --micro_opt=module=example \
    --rpc-dispatcher_out=. --rpc-dispatcher_opt=module=example \
    "${proto}"
done

echo ""
echo "✓ 生成完成!"
echo "生成的文件:"
find . -name "*_dispatcher_gen.go" -o -name "*.pb.go" -o -name "*.pb.micro.go" 2>/dev/null | sort