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
        └── pb/
            ├── user.pb.go                  ← protoc-gen-go
            ├── user.pb.micro.go            ← protoc-gen-micro
            └── user_dispatcher_gen.go      ← protoc-gen-rpc-dispatcher（与 pb 同包）
```

### `user_dispatcher_gen.go` 包含：

| 生成物 | 说明 |
|:---|:---|
| `UserServer` 接口 | 你需要实现的业务接口（与 pb 同包，无需额外 import） |
| `CallAPI(srv)` 函数 | 传入业务实现，返回可直接作为 gRPC handler 使用的函数 |

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

### 2. CallAPI 直接使用 `CallAPI(s)`，一行搞定

```go
func (s *userSvcImpl) CallAPI(ctx context.Context, req *commonpb.APIRequest) (*commonpb.APIResponse, error) {
    return userpb.CallAPI(s)(ctx, req)
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