import Foundation
import Network

class TCPServer: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var connectedClients: [String] = []
    @Published var receivedMessages: [String] = []
    
    private var listener: NWListener?
    private var port: UInt16 = 8080
    private var activeConnections: [String: NWConnection] = [:]
    
    func start(port: UInt16) {
        self.port = port
        
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        
        do {
            let portEndpoint = NWEndpoint.Port(rawValue: port)!
            listener = try NWListener(using: parameters, on: portEndpoint)
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }
            
            listener?.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    switch state {
                    case .ready:
                        self.isRunning = true
                        self.addMessage("[서버 시작] 포트 \(port)에서 대기 중...")
                    case .failed(let error):
                        self.isRunning = false
                        self.addMessage("[서버 오류] \(error.localizedDescription)")
                        self.stop()
                    case .cancelled:
                        self.isRunning = false
                        self.addMessage("[서버 중지]")
                    default:
                        break
                    }
                }
            }
            
            listener?.start(queue: .global())
            DispatchQueue.main.async { [weak self] in
                self?.addMessage("[서버 시작 중] 포트 \(port)...")
            }
            
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.addMessage("[서버 오류] 시작 실패: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleNewConnection(_ connection: NWConnection) {
        let clientID = UUID().uuidString.prefix(8)
        let clientInfo = "\(clientID)"
        let clientIDString = String(clientID)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.connectedClients.append(clientInfo)
            self.addMessage("[클라이언트 연결] \(clientInfo)")
        }
        
        // 연결 추적에 추가
        activeConnections[clientIDString] = connection
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.receiveData(from: connection, clientID: clientIDString)
                // 환영 메시지 전송
                let welcomeMessage = "서버에 연결되었습니다. (ID: \(clientIDString))"
                self?.sendData(welcomeMessage, to: connection)
            case .failed(_), .cancelled:
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if let index = self.connectedClients.firstIndex(of: clientInfo) {
                        self.connectedClients.remove(at: index)
                    }
                    self.activeConnections.removeValue(forKey: clientIDString)
                    self.addMessage("[클라이언트 연결 해제] \(clientIDString)")
                }
            default:
                break
            }
        }
        
        connection.start(queue: .global())
    }
    
    private func receiveData(from connection: NWConnection, clientID: String) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, context, isComplete, error in
            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    self?.addMessage("[수신 오류] \(clientID): \(error.localizedDescription)")
                }
                return
            }
            
            if let data = data, !data.isEmpty {
                let message = String(data: data, encoding: .utf8) ?? "[바이너리 데이터]"
                DispatchQueue.main.async { [weak self] in
                    self?.addMessage("[수신] \(clientID): \(message)")
                }
                
                // 에코 응답 전송
                let echoMessage = "에코: \(message)"
                self?.sendData(echoMessage, to: connection)
            }
            
            // 다음 데이터 수신 계속
            if connection.state == .ready {
                self?.receiveData(from: connection, clientID: clientID)
            }
        }
    }
    
    private func sendData(_ message: String, to connection: NWConnection) {
        guard let data = message.data(using: .utf8) else { return }
        
        connection.send(content: data, completion: .contentProcessed { [weak self] error in
            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    self?.addMessage("[전송 오류] \(error.localizedDescription)")
                }
            }
        })
    }
    
    func stop() {
        // 모든 활성 연결 닫기
        for (_, connection) in activeConnections {
            connection.cancel()
        }
        activeConnections.removeAll()
        
        // 리스너 중지
        listener?.cancel()
        listener = nil
        
        // 상태 초기화
        connectedClients.removeAll()
        isRunning = false
        
        addMessage("[서버 중지] 모든 연결이 종료되었습니다.")
    }
    
    func broadcastMessage(_ message: String) {
        // 현재는 단일 클라이언트만 지원
        // 향후 여러 클라이언트 연결 시 브로드캐스트 기능 추가 가능
        addMessage("[브로드캐스트] \(message)")
    }
    
    private func addMessage(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        receivedMessages.append("[\(timestamp)] \(message)")
    }
    
    deinit {
        stop()
    }
}

