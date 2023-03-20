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
    private var stack: [Chip] = []
    private let semaphore = DispatchSemaphore(value: 1)
    
    func push(_ chip: Chip) {
        semaphore.wait()
        stack.append(chip)
        semaphore.signal()
    }
    
    func pop() -> Chip? {
        semaphore.wait()
        defer { semaphore.signal() }
        return stack.popLast()
    }
}

class GeneratingThread {
    let storage: Storage
    
    init(storage: Storage) {
        self.storage = storage
    }
    
    func start() {
        DispatchQueue.global().async { [weak self] in
            let startTime = Date().timeIntervalSince1970
            while Date().timeIntervalSince1970 - startTime < 20 {
                let chip = Chip.make()
                self?.storage.push(chip)
                print("Создан Chip типа: \(chip.chipType)")
                sleep(2)
            }
        }
    }
}

class WorkerThread {
    let storage: Storage
    
    init(storage: Storage) {
        self.storage = storage
    }
    
    func start() {
        DispatchQueue.global().async { [weak self] in
            while true {
                if let chip = self?.storage.pop() {
                    print("Обработан Chip типа: \(chip.chipType)")
                    chip.soldering()
                } else {
                    break
                }
            }
        }
    }
}

let storage = Storage()
let generatingThread = GeneratingThread(storage: storage)
let workerThread = WorkerThread(storage: storage)

let group = DispatchGroup()

group.enter()
generatingThread.start()
group.leave()

group.enter()
workerThread.start()
group.leave()

group.wait()
