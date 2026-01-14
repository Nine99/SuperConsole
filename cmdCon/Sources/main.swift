import Foundation
import Network
import Darwin

class TCPClient {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "tcp.client.queue")
    private var isConnected = false
    private var shouldReceive = true
    
    func connect(host: String, port: UInt16) {
        let hostEndpoint = NWEndpoint.Host(host)
        let portEndpoint = NWEndpoint.Port(rawValue: port)!
        let endpoint = NWEndpoint.hostPort(host: hostEndpoint, port: portEndpoint)
        
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        
        connection = NWConnection(to: endpoint, using: parameters)
        
        connection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.isConnected = true
                print("✅ 서버에 연결되었습니다: \(host):\(port)")
                self?.startReceiving()
            case .waiting(let error):
                print("⏳ 연결 대기 중: \(error.localizedDescription)")
            case .failed(let error):
                print("❌ 연결 실패: \(error.localizedDescription)")
                self?.isConnected = false
            case .cancelled:
                print("🔌 연결이 종료되었습니다.")
                self?.isConnected = false
            default:
                break
            }
        }
        
        connection?.start(queue: queue)
    }
    
    private func startReceiving() {
        guard let connection = connection, shouldReceive else { return }
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, context, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                if self.isConnected {
                    print("❌ 수신 오류: \(error.localizedDescription)")
                }
                return
            }
            
            if let data = data, !data.isEmpty {
                let message = String(data: data, encoding: .utf8) ?? "[바이너리 데이터]"
                print("📥 \(message)")
            }
            
            if self.isConnected && self.shouldReceive {
                self.startReceiving()
            }
        }
    }
    
    func send(_ message: String) {
        guard isConnected, let connection = connection else {
            print("❌ 연결되지 않았습니다.")
            return
        }
        
        guard let data = message.data(using: .utf8) else {
            print("❌ 메시지를 전송할 수 없습니다.")
            return
        }
        
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("❌ 전송 오류: \(error.localizedDescription)")
            }
        })
    }
    
    func disconnect() {
        shouldReceive = false
        isConnected = false
        connection?.cancel()
        connection = nil
    }
    
    deinit {
        disconnect()
    }
}

func printUsage() {
    print("""
    사용법:
      cmdCon <host> <port>
    
    예시:
      cmdCon 127.0.0.1 8080
    
    명령어:
      연결 후 입력한 메시지를 서버로 전송합니다.
      종료하려면 'quit' 또는 'exit'를 입력하거나 Ctrl+C를 누르세요.
    """)
}

// 전역 변수로 signal 핸들러에서 접근 가능하게 함
var globalClient: TCPClient?

func signalHandler(_ signal: Int32) {
    print("\n\n연결을 종료합니다...")
    globalClient?.disconnect()
    exit(0)
}

func main() {
    let arguments = CommandLine.arguments
    
    if arguments.count < 3 {
        printUsage()
        exit(1)
    }
    
    guard let port = UInt16(arguments[2]) else {
        print("❌ 잘못된 포트 번호입니다: \(arguments[2])")
        exit(1)
    }
    
    let host = arguments[1]
    let client = TCPClient()
    globalClient = client
    
    // 종료 신호 처리
    signal(SIGINT, signalHandler)
    
    client.connect(host: host, port: port)
    
    // 연결이 될 때까지 대기
    Thread.sleep(forTimeInterval: 1.0)
    
    print("\n메시지를 입력하세요 (종료: quit 또는 exit):\n")
    
    // 대화형 모드
    while true {
        guard let input = readLine(), !input.isEmpty else {
            continue
        }
        
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedInput.lowercased() == "quit" || trimmedInput.lowercased() == "exit" {
            print("연결을 종료합니다...")
            client.disconnect()
            break
        }
        
        client.send(trimmedInput)
    }
}

main()
