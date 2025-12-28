import SwiftUI
import AppKit

class WindowDelegate: NSObject, NSWindowDelegate {
	var onWindowWillClose: (() -> Void)?
	
	func windowWillClose(_ notification: Notification) {
		onWindowWillClose?()
	}
}

struct ServerView: View {
	@StateObject private var server = TCPServer()
	@State private var port: String = "8080"
	@Environment(\.scenePhase) private var scenePhase
	@State private var windowDelegate = WindowDelegate()
	
	var body: some View {
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
			.background(Color(NSColor.controlBackgroundColor))
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
			.background(Color(NSColor.controlBackgroundColor))
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
					VStack(alignment: .leading, spacing: 0) {
						ForEach(server.receivedMessages, id: \.self) { message in
							Text(message)
							//                                    .font(.system(.caption, design: .monospaced))
								.font(.system(size: 13, design: .monospaced))
								.padding(2)
								.frame(maxWidth: .infinity, alignment: .leading)
								.background(Color(NSColor.textBackgroundColor))
								.cornerRadius(6)
						}
					}
				}
				.frame(maxHeight: 400)
			}
			.padding()
			.background(Color(NSColor.controlBackgroundColor))
			.cornerRadius(10)
			
			Spacer()
		}
		.padding()
		.navigationTitle("TCP 서버")
		.background(WindowAccessor(windowDelegate: windowDelegate))
		.onAppear {
			// 윈도우가 닫힐 때 서버 정리
			windowDelegate.onWindowWillClose = {
				if server.isRunning {
					server.stop()
				}
			}
		}
		.onChange(of: scenePhase) { oldPhase, newPhase in
			if newPhase == .inactive || newPhase == .background {
				// 앱이 백그라운드로 가거나 비활성화될 때 서버 중지
				if server.isRunning {
					server.stop()
				}
			}
		}
		.onDisappear {
			// 뷰가 사라질 때 서버 중지
			if server.isRunning {
				server.stop()
			}
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

struct WindowAccessor: NSViewRepresentable {
	let windowDelegate: WindowDelegate
	
	func makeNSView(context: Context) -> NSView {
		let view = NSView()
		DispatchQueue.main.async {
			if let window = view.window {
				window.delegate = windowDelegate
			}
		}
		return view
	}
	
	func updateNSView(_ nsView: NSView, context: Context) {
		DispatchQueue.main.async {
			if let window = nsView.window {
				window.delegate = windowDelegate
			}
		}
	}
}

#Preview {
	ServerView()
}

