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
