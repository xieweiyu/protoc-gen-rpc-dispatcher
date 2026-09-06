package main

import (
	"context"
	"fmt"
	"log"

	commonpb "example/proto/common/pb"
	userpb "example/proto/user/pb"
	"go-micro.dev/v4"
	"go-micro.dev/v4/client"
)

// ============================================================
// 1. 业务实现：实现 UserServer 接口（protoc-gen-rpc-dispatcher 生成）
//    这是 dispatcher 分发调用的目标，签名是 (ctx, req) (resp, error)
// ============================================================

type bizImpl struct{}

func (s *bizImpl) GetUserInfo(ctx context.Context, req *userpb.GetUserInfoRequest) (*userpb.GetUserInfoResponse, error) {
	return &userpb.GetUserInfoResponse{
		Id:       req.UserId,
		Username: "alice",
		Email:    "alice@example.com",
	}, nil
}

func (s *bizImpl) Login(ctx context.Context, req *userpb.LoginRequest) (*userpb.LoginResponse, error) {
	return &userpb.LoginResponse{
		Success:  true,
		Token:    "jwt-token-xxx",
		Nickname: "Alice",
	}, nil
}

// 启动时注册业务实现，CallAPI 里就能自动分发到上面的业务方法
func init() {
	userpb.Register(&bizImpl{})
}

// ============================================================
// 2. gRPC handler：实现 go-micro 生成的 UserHandler 接口
//    对外只暴露 CallAPI，其他方法不走网络
// ============================================================

type userHandler struct{}

func (h *userHandler) CallAPI(ctx context.Context, req *commonpb.APIRequest, out *commonpb.APIResponse) error {
	resp, err := userpb.CallAPI(ctx, req)
	if err != nil {
		return err
	}
	*out = *resp
	return nil
}

// 以下方法不通过 gRPC 暴露（由 CallAPI 内部调度），返回未实现
func (h *userHandler) GetUserInfo(ctx context.Context, req *userpb.GetUserInfoRequest, out *userpb.GetUserInfoResponse) error {
	return nil
}

func (h *userHandler) Login(ctx context.Context, req *userpb.LoginRequest, out *userpb.LoginResponse) error {
	return nil
}

// ============================================================
// 3. 启动 go-micro 服务
// ============================================================

func main() {
	service := micro.NewService()
	service.Init()

	if err := userpb.RegisterUserHandler(service.Server(), &userHandler{}); err != nil {
		log.Fatal(err)
	}

	if err := service.Run(); err != nil {
		log.Fatal(err)
	}
}

// ============================================================
// 4. 客户端请求示例
//    通过 go-micro client 调用 User 服务的 CallAPI
// ============================================================

// Client 演示如何通过 CallAPI 发起请求
// 网关场景: POST /user/getUserInfo -> CallAPI{Action: "getUserInfo", Params: "..."}
func Client() {
	// 创建 User 服务客户端（"user" 是注册到服务发现的服务名）
	svc := userpb.NewUserService("user", client.DefaultClient)
	ctx := context.Background()

	// 示例 1: 获取用户信息
	resp, err := svc.CallAPI(ctx, &commonpb.APIRequest{
		Action: "getUserInfo",
		Params: `{"userId": "1001"}`,
	})
	if err != nil {
		log.Fatalf("call getUserInfo failed: %v", err)
	}
	fmt.Printf("getUserInfo -> code=%d msg=%s data=%s\n", resp.Code, resp.Message, resp.Data)

	// 示例 2: 登录
	resp, err = svc.CallAPI(ctx, &commonpb.APIRequest{
		Action: "login",
		Params: `{"username": "alice", "password": "123456"}`,
	})
	if err != nil {
		log.Fatalf("call login failed: %v", err)
	}
	fmt.Printf("login -> code=%d msg=%s data=%s\n", resp.Code, resp.Message, resp.Data)

	// 示例 3: 不存在的 action，返回 404
	resp, err = svc.CallAPI(ctx, &commonpb.APIRequest{
		Action: "notExist",
		Params: `{}`,
	})
	if err != nil {
		log.Fatalf("call failed: %v", err)
	}
	fmt.Printf("notExist -> code=%d msg=%s\n", resp.Code, resp.Message)
}
