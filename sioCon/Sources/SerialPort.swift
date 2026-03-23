import Foundation
import Darwin

// MARK: - Baud Rate

struct BaudRate {
    let value: Int
    var speedValue: speed_t {
        switch value {
        case 300: return speed_t(B300)
        case 1200: return speed_t(B1200)
        case 2400: return speed_t(B2400)
        case 4800: return speed_t(B4800)
        case 9600: return speed_t(B9600)
        case 19200: return speed_t(B19200)
        case 38400: return speed_t(B38400)
        case 57600: return speed_t(B57600)
        case 115200: return speed_t(B115200)
        case 230400: return speed_t(B230400)
        default: return speed_t(B115200)
        }
    }
    
    static func parse(_ string: String) -> BaudRate? {
        guard let v = Int(string), [9600, 19200, 38400, 57600, 115200, 230400].contains(v) else { return nil }
        return BaudRate(value: v)
    }
}

// MARK: - Serial Port

final class SerialPort {
    private var fileDescriptor: Int32 = -1
    private var readSource: DispatchSourceRead?
    private let readQueue = DispatchQueue(label: "sioCon.serialRead")
    
    var onReceive: ((String) -> Void)?
    private(set) var isConnected = false
    
    static func availablePorts() -> [String] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(atPath: "/dev") else { return [] }
        return contents
            .filter { $0.hasPrefix("cu.") && $0 != "cu.Bluetooth-Incoming-Port" }
            .map { "/dev/\($0)" }
            .sorted()
    }
    
    func connect(portPath: String, baudRate: BaudRate) -> Bool {
        guard !isConnected else { return false }
        
        let fd = Darwin.open(portPath, O_RDWR | O_NOCTTY)
        guard fd >= 0 else {
            fputs("열기 실패: \(String(cString: strerror(errno)))\n", stderr)
            return false
        }
        
        var options = termios()
        guard tcgetattr(fd, &options) == 0 else {
            Darwin.close(fd)
            fputs("termios 가져오기 실패\n", stderr)
            return false
        }
        
        cfsetispeed(&options, baudRate.speedValue)
        cfsetospeed(&options, baudRate.speedValue)
        options.c_cflag |= (tcflag_t(CS8) | tcflag_t(CREAD) | tcflag_t(CLOCAL))
        options.c_lflag &= ~tcflag_t(ICANON | ECHO | ECHOE | ISIG)
        options.c_iflag &= ~tcflag_t(IXON | IXOFF | IXANY | INLCR | ICRNL)
        options.c_oflag &= ~tcflag_t(OPOST)
        
        guard tcsetattr(fd, TCSANOW, &options) == 0 else {
            Darwin.close(fd)
            fputs("termios 설정 실패\n", stderr)
            return false
        }
        
        fileDescriptor = fd
        isConnected = true
        
        readSource = DispatchSource.makeReadSource(fileDescriptor: fd, queue: readQueue)
        readSource?.setEventHandler { [weak self] in
            self?.readAvailable()
        }
        readSource?.setCancelHandler { [weak self] in
            guard let self = self, self.fileDescriptor >= 0 else { return }
            Darwin.close(self.fileDescriptor)
            self.fileDescriptor = -1
        }
        readSource?.resume()
        
        return true
    }
    
    func disconnect() {
        readSource?.cancel()
        readSource = nil
        if fileDescriptor >= 0 {
            Darwin.close(fileDescriptor)
            fileDescriptor = -1
        }
        isConnected = false
    }
    
    private func readAvailable() {
        guard fileDescriptor >= 0 else { return }
        var buffer = [UInt8](repeating: 0, count: 4096)
        let count = read(fileDescriptor, &buffer, buffer.count)
        guard count > 0 else { return }
        let data = Data(bytes: buffer, count: count)
        if let text = String(data: data, encoding: .utf8) {
            onReceive?(text)
        } else {
            onReceive?(data.map { String(format: "%02X", $0) }.joined(separator: " "))
        }
    }
    
    func send(text: String) -> Bool {
        guard isConnected, fileDescriptor >= 0 else { return false }
        guard let data = text.data(using: .utf8) else { return false }
        return data.withUnsafeBytes { buf in
            guard let base = buf.baseAddress else { return false }
            let written = write(fileDescriptor, base, data.count)
            return written == data.count
        }
    }
    
    func sendLine(_ line: String) -> Bool {
        send(text: line + "\n")
    }
    
    deinit {
        disconnect()
    }
}
