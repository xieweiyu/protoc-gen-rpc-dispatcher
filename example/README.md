# 示例：protoc-gen-rpc-dispatcher 使用

## 目录结构

```
example/
├── proto/
│   ├── common.proto       # 公共 APIRequest / APIResponse 定义
│   └── user.proto         # 用户服务，含 is_dispatcher 标记
└── gen_proto.sh           # 代码生成脚本
```

## 生成的代码

运行 `bash gen_proto.sh` 后，会生成：

```
example/
├── proto/
│   ├── common.pb.go
│   ├── user.pb.go
│   └── user/
│       └── pb/
│           └── user_dispatcher_gen.go  ← 自动生成的调度器
```

## 生成的文件内容

### `user_dispatcher_gen.go` 包含：

- **`UserServer` 接口** — 你需要实现的业务接口
- **`UserDispatcher` 结构体** — 自动调度的核心
- **`NewUserDispatcher()`** — 构造函数
- **`Dispatch(ctx, action, data)`** — 统一调度入口
- **每个 RPC 的 wrapper handler** — 自动 JSON 序列化/反序列化

## 在你的服务中使用

```go
package main

import (
    "context"
    "encoding/json"
    pb "example/proto/user/pb"
    "example/proto/user/pb/userdispatcher"
)

// 实现业务接口
type UserSvc struct{}

func (s *UserSvc) GetUserInfo(ctx context.Context, req *pb.GetUserInfoRequest) (*pb.GetUserInfoResponse, error) {
    // 你的业务逻辑
    return &pb.GetUserInfoResponse{
        Id:       req.UserId,
        Username: "alice",
        Email:    "alice@example.com",
    }, nil
}

func (s *UserSvc) Login(ctx context.Context, req *pb.LoginRequest) (*pb.LoginResponse, error) {
    // 你的业务逻辑
    return &pb.LoginResponse{Success: true, Token: "xxx", Nickname: "Alice"}, nil
}

func main() {
    dispatcher := userdispatcher.NewUserDispatcher(&UserSvc{})

    // 在 CallAPI 中使用:
    // data, err := dispatcher.Dispatch(ctx, req.Action, []byte(req.Params))
}
```