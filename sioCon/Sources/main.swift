import Foundation

var globalSerial: SerialPort?

func signalHandler(_ signal: Int32) {
    print("\n연결을 종료합니다...")
    globalSerial?.disconnect()
    exit(0)
}

func printUsage() {
    print("""
    사용법:
      sioCon --list
      sioCon <포트경로> [전송속도]

    예시:
      sioCon --list
      sioCon /dev/cu.usbserial-0001
      sioCon /dev/cu.usbserial-0001 115200

    전송속도: 9600, 19200, 38400, 57600, 115200, 230400 (기본: 115200)

    연결 후 입력한 내용을 시리얼로 전송합니다.
    수신 데이터는 화면에 출력됩니다.
    종료: quit 또는 exit 입력, 또는 Ctrl+C
    """)
}

func main() {
    let args = CommandLine.arguments.dropFirst()
    
    if args.isEmpty {
        printUsage()
        exit(1)
    }
    
    if args.first == "--list" {
        let ports = SerialPort.availablePorts()
        if ports.isEmpty {
            print("사용 가능한 시리얼 포트가 없습니다.")
        } else {
            print("사용 가능한 시리얼 포트:")
            for p in ports { print("  \(p)") }
        }
        exit(0)
    }
    
    guard let portPath = args.first, !portPath.isEmpty else {
        fputs("포트 경로를 지정하세요.\n", stderr)
        printUsage()
        exit(1)
    }
    
    let baudRate: BaudRate
    if let baudStr = args.dropFirst().first, let b = BaudRate.parse(baudStr) {
        baudRate = b
    } else {
        baudRate = BaudRate(value: 115200)
    }
    
    let serial = SerialPort()
    globalSerial = serial
    
    serial.onReceive = { text in
        print("> " + text, terminator: "")
        fflush(stdout)
    }
    
    signal(SIGINT, signalHandler)
    
    guard serial.connect(portPath: portPath, baudRate: baudRate) else {
        exit(1)
    }
    
    print("✅ 시리얼 연결됨: \(portPath) @ \(baudRate.value)")
    print("메시지 입력 (종료: quit 또는 exit)\n")
    
    while true {
        guard let input = readLine() else { break }
        let line = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if line.lowercased() == "quit" || line.lowercased() == "exit" {
            break
        }
        if !line.isEmpty {
            if !serial.sendLine(line) {
                fputs("전송 실패\n", stderr)
            }
        }
    }
    
    serial.disconnect()
    print("연결을 종료했습니다.")
}

main()
