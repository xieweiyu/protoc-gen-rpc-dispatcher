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

// ============================================================
// 1. 实现业务接口（由 protoc-gen-rpc-dispatcher 生成的 UserServer）
// ============================================================

type userSvcImpl struct{}

func (s *userSvcImpl) GetUserInfo(ctx context.Context, req *userpb.GetUserInfoRequest) (*userpb.GetUserInfoResponse, error) {
	// 你的业务逻辑
	return &userpb.GetUserInfoResponse{
		Id:       req.UserId,
		Username: "alice",
		Email:    "alice@example.com",
	}, nil
}

func (s *userSvcImpl) Login(ctx context.Context, req *userpb.LoginRequest) (*userpb.LoginResponse, error) {
	// 你的业务逻辑
	return &userpb.LoginResponse{
		Success:  true,
		Token:    "jwt-token-xxx",
		Nickname: "Alice",
	}, nil
}

// ============================================================
// 2. 创建 gRPC 服务，将 dispatcher 嵌入其中
// ============================================================

// userServer 是 gRPC 服务，嵌入 dispatcher 的 CallAPI 逻辑
type userServer struct {
	userpb.UnimplementedUserServer
	dispatcher *dispatcher.UserDispatcher
}

func newUserServer() *userServer {
	return &userServer{
		// NewUserDispatcher 接收业务接口实现，返回调度器
		dispatcher: dispatcher.NewUserDispatcher(&userSvcImpl{}),
	}
}

// CallAPI 直接委托给 dispatcher，一行搞定
func (s *userServer) CallAPI(ctx context.Context, req *pb.APIRequest) (*pb.APIResponse, error) {
	return s.dispatcher.CallAPI(ctx, req)
}

// ============================================================
// 3. 启动服务
// ============================================================

func main() {
	lis, err := net.Listen("tcp", ":8080")
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	srv := grpc.NewServer()
	userpb.RegisterUserServer(srv, newUserServer())

	log.Println("server listening at :8080")
	if err := srv.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}