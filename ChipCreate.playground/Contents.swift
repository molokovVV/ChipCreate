import Foundation

public struct Chip {
    public enum ChipType: UInt32 {
        case small = 1
        case medium
        case big
    }
    
    public let chipType: ChipType
    
    public static func make() -> Chip {
        guard let chipType = Chip.ChipType(rawValue: UInt32(arc4random_uniform(3) + 1)) else {
            fatalError("Incorrect random value")
        }
        
        return Chip(chipType: chipType)
    }
    
    public func soldering() {
        let solderingTime = chipType.rawValue
        sleep(solderingTime)
    }
}

class Storage {
    private var chips: [Chip] = []
    private let lock = NSLock()

    func push(_ chip: Chip) {
        lock.lock()
        defer { lock.unlock() }
        chips.append(chip)
    }

    func pop() -> Chip? {
        lock.lock()
        defer { lock.unlock() }
        return chips.popLast()
    }

    var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return chips.isEmpty
    }
}

class GeneratingThread: Thread {
    private let storage: Storage

    init(storage: Storage) {
        self.storage = storage
    }

    override func main() {
        let startTime = Date().timeIntervalSinceReferenceDate
        while Date().timeIntervalSinceReferenceDate - startTime < 20 {
            let chip = Chip.make()
            storage.push(chip)
            print("Создан Chip типа: \(chip.chipType)")
            GeneratingThread.sleep(forTimeInterval: 2)
        }
    }
}

class WorkerThread: Thread {
    private let storage: Storage

    init(storage: Storage) {
        self.storage = storage
    }

    override func main() {
        while !storage.isEmpty || !isCancelled {
            if let chip = storage.pop() {
                chip.soldering()
                print("Обработан Chip типа: \(chip.chipType)")
            } else {
                WorkerThread.sleep(forTimeInterval: 1)
            }
        }
    }
}

let storage = Storage()
let generatorThread = GeneratingThread(storage: storage)
let workerThread = WorkerThread(storage: storage)

generatorThread.start()
workerThread.start()

while !generatorThread.isFinished {
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
}

workerThread.cancel()

while !workerThread.isFinished {
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
}

