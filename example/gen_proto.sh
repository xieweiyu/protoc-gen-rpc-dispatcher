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

# 切换到脚本目录，之后的路径全用相对路径
cd "$SCRIPT_DIR"
cmd=`
protoc -I=./proto \
  -I="${SCRIPT_DIR}/../proto" \
  --go_out=. --go_opt=module=example \
  --rpc-dispatcher_out=. --rpc-dispatcher_opt=module=example \
  ./proto/*.proto
`
echo "$cmd"
echo ""
echo "✓ 生成完成!"
echo "生成的文件:"
find . -name "*_dispatcher_gen.go" -o -name "*.pb.go" 2>/dev/null | sort