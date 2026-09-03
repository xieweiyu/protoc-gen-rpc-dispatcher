# protoc-gen-rpc-dispatcher

protoc 插件，从 proto 文件自动生成 RPC 调度器（Dispatcher）。

## 解决了什么问题

在微服务架构中，经常需要一个**统一入口 RPC**（如 `CallAPI`）来接收请求，然后根据 `action` 字符串分发到不同的业务处理函数。传统做法需要手写大量重复的 JSON 序列化/反序列化代码和 action 路由。

**protoc-gen-rpc-dispatcher** 自动完成这些工作：

1. 读取 proto 中定义的所有 RPC
2. 生成 `Server` 接口（你只需要实现业务逻辑）
3. 生成 `Dispatcher` 结构体（自动完成 JSON 编解码和路由分发）
4. 标记为 `is_dispatcher` 的 RPC 会被跳过（作为统一入口）

## 安装

```bash
go install github.com/xieweiyu/protoc-gen-rpc-dispatcher@latest
```

## 快速开始

### 1. 在 proto 中定义服务

```protobuf
import "gen-dispatcher.proto";

service User {
  // 标记统一入口，插件会跳过这个 RPC
  rpc CallAPI(common.APIRequest) returns (common.APIResponse) {
option (gendispatcher.is_dispatcher) = true;
  }

  // 真正的业务 RPC，会被生成 wrapper handler
  rpc GetUserInfo(GetUserInfoRequest) returns (GetUserInfoResponse);
  rpc Login(LoginRequest) returns (LoginResponse);
}
```

### 2. 运行 protoc

```bash
protoc -I=./proto \
  -I=path/to/protoc-gen-rpc-dispatcher/proto \
  --go_out=. --go_opt=module=your.module \
  --rpc-dispatcher_out=. --rpc-dispatcher_opt=module=your.module \
  ./proto/*.proto
```

### 3. 实现业务接口

```go
type UserSvc struct{}

// 实现自动生成的 UserServer 接口
func (s *UserSvc) GetUserInfo(ctx context.Context, req *pb.GetUserInfoRequest) (*pb.GetUserInfoResponse, error) {
    return &pb.GetUserInfoResponse{Id: req.UserId, Username: "alice"}, nil
}

func (s *UserSvc) Login(ctx context.Context, req *pb.LoginRequest) (*pb.LoginResponse, error) {
    return &pb.LoginResponse{Success: true, Token: "xxx"}, nil
}
```

### 4. 在 CallAPI 中使用

```go
dispatcher := userdispatcher.NewUserDispatcher(&UserSvc{})

func (s *UserSvc) CallAPI(ctx context.Context, req *commonpb.APIRequest) (*commonpb.APIResponse, error) {
    data, err := dispatcher.Dispatch(ctx, req.Action, []byte(req.Params))
    if err != nil {
        return &commonpb.APIResponse{Code: 500, Message: err.Error()}, nil
    }
    return &commonpb.APIResponse{Code: 0, Data: data}, nil
}
```

## 生成的代码

对于每个 proto service，会生成一个 `xxx_dispatcher_gen.go` 文件，包含：

| 生成物 | 说明 |
|:---|:---|
| `UserServer` 接口 | 你需要实现的业务接口 |
| `UserDispatcher` 结构体 | 统一调度器 |
| `NewUserDispatcher()` | 构造函数 |
| `Dispatch(ctx, action, data)` | 根据 action 分发请求 |
| `handleXxx()` | 每个 RPC 的 wrapper handler（自动 JSON 编解码） |

## 完整示例

参见 [example/](./example/) 目录。

## proto option

### `is_dispatcher`

标记一个 RPC 为统一入口，插件会跳过它，不生成 wrapper handler。

```protobuf
rpc CallAPI(APIRequest) returns (APIResponse) {
  option (genrouter.is_dispatcher) = true;
}
```

每个 service 中只能有一个 RPC 标记为 `is_dispatcher = true`。

## 插件参数

| 参数 | 说明 |
|:---|:---|
| `module=xxx` | Go module 名，用于确定输出路径（与 protoc-gen-go 一致） |
| `paths=source_relative` | 相对路径模式 |

## 工作原理

1. protoc 调用 protoc-gen-rpc-dispatcher 插件
2. 插件读取 proto 文件中的 service 和 RPC 定义
3. 跳过标记 `is_dispatcher = true` 的 RPC
4. 为每个业务 RPC 生成 wrapper handler（JSON 序列化/反序列化）
5. 生成 `Dispatcher` 结构体和 `Dispatch` 方法
6. 生成 `Server` 接口供开发者实现

## 许可证

MIT