package main

import (
	"context"
	"log"
	"net"

	"example/proto/common/pb"
	"example/proto/user/dispatcher"
	userpb "example/proto/user/pb"
	"google.golang.org/grpc"
)

// 1. 实现业务接口（由 protoc-gen-rpc-dispatcher 生成的 UserServer）
type userSvcImpl struct{}

func (s *userSvcImpl) GetUserInfo(ctx context.Context, req *userpb.GetUserInfoRequest) (*userpb.GetUserInfoResponse, error) {
	return &userpb.GetUserInfoResponse{
		Id:       req.UserId,
		Username: "alice",
		Email:    "alice@example.com",
	}, nil
}

func (s *userSvcImpl) Login(ctx context.Context, req *userpb.LoginRequest) (*userpb.LoginResponse, error) {
	return &userpb.LoginResponse{
		Success:  true,
		Token:    "jwt-token-xxx",
		Nickname: "Alice",
	}, nil
}

// 2. CallAPI 直接使用生成的调度函数，一行搞定
func (s *userSvcImpl) CallAPI(ctx context.Context, req *pb.APIRequest) (*pb.APIResponse, error) {
	return dispatcher.CallAPI(s)(ctx, req)
}

// 3. 启动 gRPC 服务
func main() {
	lis, err := net.Listen("tcp", ":8080")
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	srv := grpc.NewServer()
	userpb.RegisterUserServer(srv, &userSvcImpl{})

	log.Println("server listening at :8080")
	if err := srv.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}