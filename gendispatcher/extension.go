// Package gendispatcher 提供 protoc-gen-rpc-dispatcher 插件的选项解析
package gendispatcher

import (
	"google.golang.org/protobuf/encoding/protowire"
	"google.golang.org/protobuf/types/descriptorpb"
)

// IsDispatcherRPC 检查 MethodOptions 中是否设置了 is_dispatcher = true
// 从 unknown fields 中解析字段编号 50001
func IsDispatcherRPC(opts *descriptorpb.MethodOptions) bool {
	if opts == nil {
		return false
	}

	unknown := opts.ProtoReflect().GetUnknown()
	if len(unknown) == 0 {
		return false
	}

	// 遍历 unknown fields 的 wire 格式数据
	for len(unknown) > 0 {
		num, wtyp, n := protowire.ConsumeTag(unknown)
		if n < 0 {
			break
		}
		unknown = unknown[n:]

		// 只检查字段 50001 (is_dispatcher)
		if num != 50001 {
			// 跳过其他字段
			switch wtyp {
			case protowire.VarintType:
				_, n = protowire.ConsumeVarint(unknown)
			case protowire.Fixed32Type:
				_, n = protowire.ConsumeFixed32(unknown)
			case protowire.Fixed64Type:
				_, n = protowire.ConsumeFixed64(unknown)
			case protowire.BytesType:
				_, n = protowire.ConsumeBytes(unknown)
			default:
				return false
			}
			if n < 0 {
				break
			}
			unknown = unknown[n:]
			continue
		}

		// 字段 50001 是 bool (varint 类型)
		if wtyp != protowire.VarintType {
			return false
		}
		v, n := protowire.ConsumeVarint(unknown)
		if n < 0 {
			return false
		}
		return v != 0
	}

	return false
}