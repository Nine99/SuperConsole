import SwiftUI

struct TCPClientView: View {
    @StateObject private var networkService = NetworkService()
    @State private var host: String = "127.0.0.1"
    @State private var port: String = "8080"
    @State private var messageToSend: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 연결 설정 섹션
                VStack(alignment: .leading, spacing: 12) {
                    Text("연결 설정")
                        .font(.headline)
                    
                    HStack {
                        Text("호스트:")
                            .frame(width: 80, alignment: .leading)
                        TextField("예: 127.0.0.1", text: $host)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numbersAndPunctuation)
                    }
                    
                    HStack {
                        Text("포트:")
                            .frame(width: 80, alignment: .leading)
                        TextField("예: 8080", text: $port)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    // 연결 상태 및 버튼
                    HStack {
                        connectionStatusView
                        Spacer()
                        connectionButton
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // 메시지 입력 섹션
                VStack(alignment: .leading, spacing: 12) {
                    Text("메시지 전송")
                        .font(.headline)
                    
                    HStack {
                        TextField("메시지를 입력하세요", text: $messageToSend)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(!isConnected)
                        
                        Button("전송") {
                            sendMessage()
                        }
                        .disabled(messageToSend.isEmpty || !isConnected)
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // 수신된 메시지 섹션
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("수신된 메시지")
                            .font(.headline)
                        Spacer()
                        Button("지우기") {
                            networkService.receivedMessages.removeAll()
                        }
                        .buttonStyle(.bordered)
                        .disabled(networkService.receivedMessages.isEmpty)
                    }
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(networkService.receivedMessages, id: \.self) { message in
                                Text(message)
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
            .navigationTitle("TCP/IP 클라이언트")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var connectionStatusView: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            Text(statusText)
                .font(.subheadline)
        }
    }
    
    private var statusColor: Color {
        switch networkService.connectionState {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .error:
            return .red
        case .disconnected:
            return .gray
        }
    }
    
    private var statusText: String {
        switch networkService.connectionState {
        case .connected:
            return "연결됨"
        case .connecting:
            return "연결 중..."
        case .error(let message):
            return "오류: \(message)"
        case .disconnected:
            return "연결 안 됨"
        }
    }
    
    private var connectionButton: some View {
        Button(action: toggleConnection) {
            Text(isConnected ? "연결 해제" : "연결")
                .frame(minWidth: 100)
        }
        .buttonStyle(.borderedProminent)
        .tint(isConnected ? .red : .blue)
    }
    
    private var isConnected: Bool {
        if case .connected = networkService.connectionState {
            return true
        }
        return false
    }
    
    private func toggleConnection() {
        if isConnected {
            networkService.disconnect()
        } else {
            guard let portNumber = UInt16(port) else {
                return
            }
            networkService.connect(to: host, port: portNumber)
        }
    }
    
    private func sendMessage() {
        guard !messageToSend.isEmpty else { return }
        networkService.sendMessage(messageToSend)
        messageToSend = ""
    }
}

#Preview {
    TCPClientView()
}

