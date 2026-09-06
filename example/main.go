package main

import (
	"context"
	"log"

	commonpb "example/proto/common/pb"
	userpb "example/proto/user/pb"
	"go-micro.dev/v4"
	"go-micro.dev/v4/client"
)

// ============================================================
// 1. 实现业务接口（UserServer 由 protoc-gen-rpc-dispatcher 生成）
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

// ============================================================
// 2. 启动 go-micro 服务
//    Register 注册业务实现，生成的 userServiceHandler 自动实现 UserHandler
// ============================================================

func main() {
	service := micro.NewService()
	service.Init()

	// 注册业务实现
	userpb.Register(&bizImpl{})

	// 一行注册到 go-micro，无需手写 handler
	if err := userpb.RegisterUserHandler(service.Server(), userpb.NewUserHandler()); err != nil {
		log.Fatal(err)
	}

	if err := service.Run(); err != nil {
		log.Fatal(err)
	}
}

// ============================================================
// 3. 客户端请求示例
//    通过 go-micro client 调用 User 服务的 CallAPI
// ============================================================

// Client 演示如何通过 CallAPI 发起请求
// 网关场景: POST /user/getUserInfo -> CallAPI{Action: "getUserInfo", Params: "..."}
func Client() {
	// 创建 User 服务客户端（"user" 是注册到服务发现的服务名）
	svc := userpb.NewUserService("user", client.NewClient())
	ctx := context.Background()

	// 示例 1: 获取用户信息
	resp, err := svc.CallAPI(ctx, &commonpb.APIRequest{
		Action: "getUserInfo",
		Params: `{"userId": "1001"}`,
	})
	if err != nil {
		log.Fatalf("call getUserInfo failed: %v", err)
	}
	log.Printf("getUserInfo -> code=%d msg=%s data=%s", resp.Code, resp.Message, resp.Data)

	// 示例 2: 登录
	resp, err = svc.CallAPI(ctx, &commonpb.APIRequest{
		Action: "login",
		Params: `{"username": "alice", "password": "123456"}`,
	})
	if err != nil {
		log.Fatalf("call login failed: %v", err)
	}
	log.Printf("login -> code=%d msg=%s data=%s", resp.Code, resp.Message, resp.Data)

	// 示例 3: 不存在的 action，返回 404
	resp, err = svc.CallAPI(ctx, &commonpb.APIRequest{
		Action: "notExist",
		Params: `{}`,
	})
	if err != nil {
		log.Fatalf("call failed: %v", err)
	}
	log.Printf("notExist -> code=%d msg=%s", resp.Code, resp.Message)
}
