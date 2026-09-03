#!/usr/bin/env bash
# protoc-gen-rpc-dispatcher 示例 - 生成代码
#
# 前置条件:
#   1. 安装 protoc
#   2. 安装 protoc-gen-go: go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
#   3. 编译 protoc-gen-rpc-dispatcher: go build -o protoc-gen-rpc-dispatcher.exe ..
#
# 使用方式:
#   cd example
#   bash gen_proto.sh

# 插件路径
PLUGIN="../protoc-gen-rpc-dispatcher.exe"

protoc -I=./proto \
  -I="../proto" \
  --go_out=. --go_opt=module=example \
  --plugin=protoc-gen-rpc-dispatcher="${PLUGIN}" \
  --rpc-dispatcher_out=. --rpc-dispatcher_opt=module=example \
  ./proto/*.proto

echo ""
echo "✓ 生成完成!"
echo "生成的文件:"
find . -name "*_dispatcher_gen.go" -o -name "*.pb.go" 2>/dev/null | sort