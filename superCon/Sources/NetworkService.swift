import Foundation
import Network

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
    
    static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
             (.connecting, .connecting),
             (.connected, .connected):
            return true
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

class NetworkService: ObservableObject {
    @Published var connectionState: ConnectionState = .disconnected
    @Published var receivedMessages: [String] = []
    
    private var connection: NWConnection?
    private var host: String = ""
    private var port: UInt16 = 0
    
    func connect(to host: String, port: UInt16) {
        self.host = host
        self.port = port
        
        connectionState = .connecting
        
        let hostEndpoint = NWEndpoint.Host(host)
        let portEndpoint = NWEndpoint.Port(rawValue: port)!
        let endpoint = NWEndpoint.hostPort(host: hostEndpoint, port: portEndpoint)
        
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        
        connection = NWConnection(to: endpoint, using: parameters)
        
        connection?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.connectionState = .connected
                    self?.receiveMessage()
                case .waiting(let error):
                    self?.connectionState = .error("Waiting: \(error.localizedDescription)")
                case .failed(let error):
                    self?.connectionState = .error("Failed: \(error.localizedDescription)")
                    self?.disconnect()
                case .cancelled:
                    self?.connectionState = .disconnected
                default:
                    break
                }
            }
        }
        
        connection?.start(queue: .global())
    }
    
    func sendMessage(_ message: String) {
        guard case .connected = connectionState else {
            addReceivedMessage("[에러] 연결되지 않았습니다.")
            return
        }
        
        guard let data = message.data(using: .utf8) else {
            addReceivedMessage("[에러] 메시지를 전송할 수 없습니다.")
            return
        }
        
        connection?.send(content: data, completion: .contentProcessed { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.addReceivedMessage("[에러] 전송 실패: \(error.localizedDescription)")
                } else {
                    self?.addReceivedMessage("[전송] \(message)")
                }
            }
        })
    }
    
    private func receiveMessage() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, context, isComplete, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.connectionState = .error("수신 오류: \(error.localizedDescription)")
                    return
                }
                
                if let data = data, !data.isEmpty {
                    let message = String(data: data, encoding: .utf8) ?? "[바이너리 데이터]"
                    self?.addReceivedMessage("[수신] \(message)")
                }
                
                // 다음 메시지를 계속 수신
                if self?.connectionState == .connected {
                    self?.receiveMessage()
                }
            }
        }
    }
    
    private func addReceivedMessage(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        receivedMessages.append("[\(timestamp)] \(message)")
    }
    
    func disconnect() {
        connection?.cancel()
        connection = nil
        connectionState = .disconnected
    }
    
    deinit {
        disconnect()
    }
}

