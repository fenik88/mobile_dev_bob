import Foundation
import Network
import Combine

// синглтончик
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected: Bool = true //приватный сеттер

    private let monitor = NWPathMonitor()// системный наблюдатель
    private let queue = DispatchQueue(label: "NetworkMonitor")// фоновый поток чтобы не нагружать основу

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in //слабая ссылка для автоматического сборщика мусора
            DispatchQueue.main.async {//переключение на основной поток для обновления юишки
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {//деструктор
        monitor.cancel()
    }
}
