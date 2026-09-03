# 示例：protoc-gen-rpc-dispatcher 使用

## 目录结构

```
example/
├── proto/
│   ├── common.proto           # 公共 APIRequest / APIResponse 定义
│   └── user.proto             # 用户服务，含 is_dispatcher 标记
├── gen_proto.sh               # 代码生成脚本
├── main.go                    # 完整的使用示例
├── go.mod / go.sum
```

## 运行

```bash
# 1. 生成代码
bash gen_proto.sh

# 2. 运行示例
go run main.go
```

## 生成的代码

`bash gen_proto.sh` 会生成：

```
example/
└── proto/
    ├── common.pb.go
    ├── user.pb.go
    └── user/
        └── dispatcher/
            └── user_dispatcher_gen.go  ← 自动生成的调度器
```

### `user_dispatcher_gen.go` 包含：

| 生成物 | 说明 |
|:---|:---|
| `UserServer` 接口 | 你需要实现的业务接口 |
| `UserDispatcher` 结构体 | 统一调度器，包含 `CallAPI` 方法 |
| `NewUserDispatcher(srv)` | 构造函数，接收业务接口实现 |
| `CallAPI(ctx, req)` | 直接作为 gRPC handler 使用 |
| `handleXxx()` | 每个 RPC 的 wrapper handler（自动 JSON 编解码） |

## 使用流程

### 1. 实现业务接口

```go
type userSvcImpl struct{}

func (s *userSvcImpl) GetUserInfo(ctx context.Context, req *userpb.GetUserInfoRequest) (*userpb.GetUserInfoResponse, error) {
    return &userpb.GetUserInfoResponse{Id: req.UserId, Username: "alice"}, nil
}

func (s *userSvcImpl) Login(ctx context.Context, req *userpb.LoginRequest) (*userpb.LoginResponse, error) {
    return &userpb.LoginResponse{Success: true, Token: "xxx"}, nil
}
```

### 2. 创建 gRPC 服务，嵌入 dispatcher

```go
type userServer struct {
    userpb.UnimplementedUserServer
    dispatcher *userdispatcher.UserDispatcher
}

func newUserServer() *userServer {
    return &userServer{
        dispatcher: userdispatcher.NewUserDispatcher(&userSvcImpl{}),
    }
}

// CallAPI 一行委托给 dispatcher
func (s *userServer) CallAPI(ctx context.Context, req *commonpb.APIRequest) (*commonpb.APIResponse, error) {
    return s.dispatcher.CallAPI(ctx, req)
}
```

### 3. 注册到 gRPC 并启动

```go
func main() {
    srv := grpc.NewServer()
    userpb.RegisterUserServer(srv, newUserServer())
    // ...
}
```

完整代码见 [main.go](./main.go)。