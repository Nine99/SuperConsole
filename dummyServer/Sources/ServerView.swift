import SwiftUI

struct ServerView: View {
    @StateObject private var server = TCPServer()
    @State private var port: String = "8080"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 서버 제어 섹션
                VStack(alignment: .leading, spacing: 12) {
                    Text("서버 설정")
                        .font(.headline)
                    
                    HStack {
                        Text("포트:")
                            .frame(width: 80, alignment: .leading)
                        TextField("예: 8080", text: $port)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .disabled(server.isRunning)
                        
                        Button(action: toggleServer) {
                            Text(server.isRunning ? "중지" : "시작")
                                .frame(minWidth: 100)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(server.isRunning ? .red : .green)
                        .disabled(port.isEmpty)
                    }
                    
                    // 서버 상태
                    HStack {
                        Circle()
                            .fill(server.isRunning ? .green : .gray)
                            .frame(width: 12, height: 12)
                        Text(server.isRunning ? "실행 중" : "중지됨")
                            .font(.subheadline)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // 연결된 클라이언트 섹션
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("연결된 클라이언트")
                            .font(.headline)
                        Spacer()
                        Text("\(server.connectedClients.count)")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    if server.connectedClients.isEmpty {
                        Text("연결된 클라이언트가 없습니다.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(server.connectedClients, id: \.self) { client in
                                    Text(client)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // 로그 섹션
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("서버 로그")
                            .font(.headline)
                        Spacer()
                        Button("지우기") {
                            server.receivedMessages.removeAll()
                        }
                        .buttonStyle(.bordered)
                        .disabled(server.receivedMessages.isEmpty)
                    }
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(server.receivedMessages, id: \.self) { message in
                                Text(message)
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .frame(maxHeight: 400)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
            .navigationTitle("TCP 서버")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func toggleServer() {
        if server.isRunning {
            server.stop()
        } else {
            guard let portNumber = UInt16(port) else {
                return
            }
            server.start(port: portNumber)
        }
    }
}

#Preview {
    ServerView()
}

