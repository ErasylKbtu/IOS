// =============================================================
//  Station ALMA-7, Part III: The Repair Fleet
//  iOS Mobile Development · Module 5 · Lab Assignment
//
//  How to use:
//   • Xcode: File → New → Playground → Blank, replace everything
//     with this file's contents.
//   • Terminal: swift ALMA7_Part3_Starter.swift
//
//  Rules:
//   • Do NOT modify the STARTER DATA section. LegacyBeacon in
//     particular must be reached with an extension, not edited.
//   • `!` (force unwrap) is forbidden: −0.5 points each.
//   • No map / filter / reduce / compactMap.
//   • The Health Rule must exist in exactly ONE place in this file.
// =============================================================


// MARK: - =================== STARTER DATA ===================
// MARK: - Do not modify anything in this section

/// Drone records recovered from the fleet registry.
/// One `kind` does not correspond to any drone type you will build.
let fleetData: [(kind: String, id: String, charge: Int)] = [
    (kind: "welder",  id: "W-1", charge: 80),
    (kind: "scanner", id: "S-1", charge: 45),
    (kind: "cargo",   id: "C-1", charge: 100),
    (kind: "welder",  id: "W-2", charge: 15),
    (kind: "scanner", id: "S-2", charge: 60),
    (kind: "tug",     id: "T-1", charge: 50)
]

/// Hull sensors. These are NOT drones — they never move and never work a shift.
let sensorData: [(id: String, charge: Int)] = [
    (id: "hull-cam", charge: 12),
    (id: "thermal",  charge: 77)
]

/// Hardware from the original station. You may not add anything to this
/// declaration — no methods, no protocols, no properties.
struct LegacyBeacon {
    let name: String
    let signalStrength: Int
}

let beacon = LegacyBeacon(name: "ALMA-BEACON", signalStrength: 8)

print("Fleet registry online: \(fleetData.count) drone records, \(sensorData.count) sensors, beacon \(beacon.name).")

// MARK: - ================= END OF STARTER DATA =================


// MARK: - =================== YOUR SOLUTION ===================

// MARK: Level 1 - The Power Cell

// A class is appropriate because several drone references can share one power cell
// and must all observe the same current charge.
private enum ChargeRules {
    static func clamp(_ value: Int) -> Int {
        max(0, min(100, value))
    }

    static func afterRecharge(_ current: Int, by amount: Int) -> Int {
        guard amount > 0 else { return current }
        // Avoid an integer overflow if a caller supplies an extremely large amount.
        if amount >= 100 - current { return 100 }
        return clamp(current + amount)
    }
}

final class PowerCell {
    private var charge: Int

    init(charge: Int) {
        self.charge = ChargeRules.clamp(charge)
    }

    func level() -> Int {
        charge
    }

    func spend(_ amount: Int) -> Bool {
        guard amount > 0, amount <= charge else { return false }
        charge -= amount
        return true
    }

    func recharge(by amount: Int) {
        charge = ChargeRules.afterRecharge(charge, by: amount)
    }
}

print("\nLEVEL 1 - PowerCell")
let cell = PowerCell(charge: 130)
print("Clamped starting charge: \(cell.level())")
print("Spend 25: \(cell.spend(25)), remaining: \(cell.level())")
print("Spend 0: \(cell.spend(0)), remaining: \(cell.level())")
print("Spend 1000: \(cell.spend(1000)), remaining: \(cell.level())")
cell.recharge(by: 100)
print("Recharge by 100, capped at: \(cell.level())")

// Encapsulation proof: this exact line was tested outside PowerCell and left disabled.
// cell.charge = 100
// Compiler error: 'charge' is inaccessible due to 'private' protection level.

// MARK: Level 2 - The Fleet

class Drone {
    let id: String
    let cell: PowerCell

    init(id: String, cell: PowerCell) {
        self.id = id
        self.cell = cell
        // Bonus, runtime abstract-base check: real drone objects must be subclasses.
        precondition(type(of: self) != Drone.self,
                     "Do not instantiate Drone directly; choose a concrete drone.")
    }

    var powerCost: Int { 10 }

    var statusLine: String {
        let charge = cell.level()
        return "\(id): \(charge)% \(charge.powerBar)"
    }

    func performTask() -> Int { 0 }

    // final ensures that every subclass checks its battery before doing work.
    // Subclasses can override powerCost and performTask, but not this safety ritual.
    final func runOnce() -> Int {
        guard cell.spend(powerCost) else { return 0 }
        return performTask()
    }
}

final class WelderDrone: Drone {
    override var powerCost: Int { 25 }
    override func performTask() -> Int { 40 }

    func weldSeam() -> String {
        "\(id) welded a hull seam."
    }
}

class ScannerDrone: Drone {
    override var powerCost: Int { 10 }
    override func performTask() -> Int { 15 }
    override var statusLine: String { super.statusLine + " [scanner]" }
}

final class CargoDrone: Drone {
    override var powerCost: Int { 20 }
    override func performTask() -> Int { 25 }
}

func makeDrone(kind: String, id: String, charge: Int) -> Drone? {
    let cell = PowerCell(charge: charge)
    switch kind {
    case "welder": return WelderDrone(id: id, cell: cell)
    case "scanner": return ScannerDrone(id: id, cell: cell)
    case "cargo": return CargoDrone(id: id, cell: cell)
    default: return nil
    }
}

print("\nLEVEL 2 - Fleet")
var builtFleet: [Drone] = []
for record in fleetData {
    guard let drone = makeDrone(kind: record.kind, id: record.id, charge: record.charge) else {
        print("Warning: unsupported drone kind '\(record.kind)' for \(record.id); skipped.")
        continue
    }
    builtFleet.append(drone)
}
let fleet: [Drone] = builtFleet
for drone in fleet {
    print("Created \(type(of: drone)): \(drone.statusLine), cost: \(drone.powerCost)")
}
let demoWelder = WelderDrone(id: "W-DEMO", cell: PowerCell(charge: 100))
print("Welder-specific action: \(demoWelder.weldSeam())")
let demoScanner = ScannerDrone(id: "S-DEMO", cell: PowerCell(charge: 70))
print("Scanner status override: \(demoScanner.statusLine)")

// MARK: Level 3 - The Shift

func runShift(_ fleet: [Drone], rounds: Int) -> Int {
    guard rounds > 0 else { return 0 }
    var workUnits = 0
    for _ in 0..<rounds {
        for drone in fleet {
            workUnits += drone.runOnce()
        }
    }
    return workUnits
}

print("\nLEVEL 3 - Three-round shift")
let A = runShift(fleet, rounds: 3)
var remainingCharge = 0
var readyForAnotherTask = 0
for drone in fleet {
    let charge = drone.cell.level()
    remainingCharge += charge
    if charge >= drone.powerCost {
        readyForAnotherTask += 1
    }
    print("After shift: \(drone.statusLine), next task costs \(drone.powerCost)")
}
let B = remainingCharge
let C = readyForAnotherTask
print("Work units (A): \(A)")
print("Remaining charge (B): \(B)")
print("Drones able to run again (C): \(C)")

// MARK: Level 4 - Diagnostics

protocol Diagnosable {
    var componentID: String { get }
    var statusCode: Int { get }
    func diagnose() -> String
}

protocol Rechargeable {
    mutating func recharge(by amount: Int)
}

// The health thresholds are declared once, in the Diagnosable extension.
// Class instance methods can mutate an object's properties without `mutating`.
extension Drone: Diagnosable, Rechargeable {
    var componentID: String { id }
    var statusCode: Int { healthCode(for: cell.level()) }

    func recharge(by amount: Int) {
        cell.recharge(by: amount)
    }
}

struct SensorModule: Diagnosable, Rechargeable {
    let id: String
    var chargeLevel: Int

    var componentID: String { id }
    var statusCode: Int { healthCode(for: chargeLevel) }

    // A struct needs `mutating` to update its own stored value.
    mutating func recharge(by amount: Int) {
        chargeLevel = ChargeRules.afterRecharge(chargeLevel, by: amount)
    }
}

func diagnosticsReport(_ components: [Diagnosable]) -> String {
    var report = "Diagnostics (\(components.count) components):"
    for component in components {
        report += "\n" + component.diagnose()
    }
    return report
}

print("\nLEVEL 4 - Diagnostics")
var sensors: [SensorModule] = []
for record in sensorData {
    sensors.append(SensorModule(id: record.id, chargeLevel: ChargeRules.clamp(record.charge)))
}
// [Drone] can contain only Drone subclasses; SensorModule is a struct,
// so [Diagnosable] is required for this mixed collection.
var components: [Diagnosable] = []
for drone in fleet { components.append(drone) }
for sensor in sensors { components.append(sensor) }
print(diagnosticsReport(components))

let rechargeDemo = WelderDrone(id: "W-RECHARGE", cell: PowerCell(charge: 5))
print("Class recharge BEFORE: \(rechargeDemo.cell.level())")
rechargeDemo.recharge(by: 30)
print("Class recharge AFTER: \(rechargeDemo.cell.level())")
var sensorDemo = SensorModule(id: "TEST-SENSOR", chargeLevel: 5)
print("Struct recharge BEFORE: \(sensorDemo.chargeLevel)")
sensorDemo.recharge(by: 30)
print("Struct recharge AFTER: \(sensorDemo.chargeLevel)")

// MARK: Level 5 - Shared Behaviour

extension Diagnosable {
    func diagnose() -> String {
        "\(componentID): code \(statusCode)"
    }

    // The Health Rule has exactly ONE implementation for every component.
    func healthCode(for chargeOrSignal: Int) -> Int {
        if chargeOrSignal < 20 { return 2 }  // critical
        if chargeOrSignal < 50 { return 1 }  // warning
        return 0                            // nominal
    }
}

// LegacyBeacon is unchanged above; an extension adds its conformance.
extension LegacyBeacon: Diagnosable {
    var componentID: String { name }
    var statusCode: Int { healthCode(for: signalStrength) }

    func diagnose() -> String {
        "LEGACY BEACON \(componentID): code \(statusCode) (signal \(signalStrength))"
    }
}

// powerBar: 42 -> "####......", -5 -> "..........", 250 -> "##########".
extension Int {
    var powerBar: String {
        let filled = Swift.max(0, Swift.min(10, self / 10))
        return String(repeating: "#", count: filled)
            + String(repeating: ".", count: 10 - filled)
    }
}

print("\nLEVEL 5 - Shared behaviour and beacon")
components.append(beacon)
print(diagnosticsReport(components))
var allStatusCodes = 0
for component in components {
    allStatusCodes += component.statusCode
}
let D = allStatusCodes
print("Total status codes (D): \(D)")
print("Power bars: 42 = \(42.powerBar), -5 = \((-5).powerBar), 250 = \(250.powerBar)")

// MARK: Level 6 - Incident Reports

/*
Report 1 — PatchDrone.performTask() lacks `override`.
Expected: the author wanted PatchDrone.runOnce() to produce 30 work units.
Actual: Swift does not compile it: overriding declaration requires an 'override' keyword.
Rule: overriding an inherited class method must be explicit in Swift.
Fix: add `override` to the subclass method.
*/
class PatchDrone: Drone {
    override func performTask() -> Int { 30 }
}
let patch = PatchDrone(id: "PATCH-1", cell: PowerCell(charge: 100))
print("\nLEVEL 6 - Incident fixes")
print("Report 1 fix: \(patch.runOnce()) work units")

/*
Report 2 — HeavyWelder tries to inherit from final WelderDrone and override final runOnce().
Expected: a heavy welder that skips normal battery rules and returns 999.
Actual: it does not compile: inheritance from a final class is forbidden, and
       a final method may not be overridden.
Rule: `final` prevents subclassing a class or overriding a final method.
Fix: inherit directly from Drone and override only powerCost and performTask.
     The inherited final runOnce() always checks charge first.
*/
final class HeavyWelder: Drone {
    override var powerCost: Int { 40 }
    override func performTask() -> Int { 60 }
}
let heavy = HeavyWelder(id: "HEAVY-1", cell: PowerCell(charge: 50))
print("Report 2 fix: work = \(heavy.runOnce()), remaining = \(heavy.cell.level())")
print("Report 2 insufficient charge: \(heavy.runOnce()), remaining = \(heavy.cell.level())")

/*
Report 3 — The variable's static type is Drone.
Expected: first.weldSeam() should call WelderDrone's extra method.
Actual: it does not compile: value of type 'Drone' has no member 'weldSeam'.
Rule: a base-class-typed reference exposes only the base class's declared API.
Fix: use a conditional downcast `as? WelderDrone` first. The result is optional
     because some Drone instances are not welders, so the cast might fail.
*/
let reportFleet: [Drone] = [WelderDrone(id: "W-9", cell: PowerCell(charge: 100))]
let first = reportFleet[0]
if let welder = first as? WelderDrone {
    print("Report 3 fix: \(welder.weldSeam())")
}

/*
Report 4 — label() exists only in a protocol extension, not in the protocol.
Expected: printing 'thruster T-1' from the concrete Thruster implementation.
Actual: the original compiles but prints 'generic component'.
Rule: extension-only methods use static dispatch when called on a protocol-
      typed value; protocol requirements use witness-table dynamic dispatch.
Fix: add `func label() -> String` to the Labelled protocol requirements.
*/
protocol Labelled {
    var componentID: String { get }
    func label() -> String
}
extension Labelled {
    func label() -> String { "generic component" }
}
struct Thruster: Labelled {
    let componentID: String
    func label() -> String { "thruster \(componentID)" }
}
let parts: [Labelled] = [Thruster(componentID: "T-1")]
print("Report 4 fix: \(parts[0].label())")

// MARK: Finale - Mission Code

let missionCode = "\(A)-\(B)-\(C)-\(D)"
print("\nMISSION CODE: \(missionCode)")

// MARK: Bonus (+1) - Abstract base choices and a protocol-based redesign

/*
Method 1, runtime: Drone.init contains a precondition checking whether the
concrete dynamic type is exactly Drone. The following would fail at runtime:

let invalidDrone = Drone(id: "BASE", cell: PowerCell(charge: 100))
// Runtime: Precondition failed: Do not instantiate Drone directly...

Method 2, compile time: replace the base class with a protocol. Protocols have
no concrete initializer and cannot be instantiated directly:

let invalid = BonusFleetDesign.FleetDrone(id: "BASE", chargeLevel: 100)
// Compiler: protocol type 'any FleetDrone' cannot be instantiated.
*/

enum BonusFleetDesign {
    protocol FleetDrone {
        var id: String { get }
        var chargeLevel: Int { get set }
        var powerCost: Int { get }
        func performTask() -> Int
    }

    struct WelderDrone: FleetDrone {
        let id: String
        var chargeLevel: Int
        var powerCost: Int { 25 }
        func performTask() -> Int { 40 }
    }

    struct ScannerDrone: FleetDrone {
        let id: String
        var chargeLevel: Int
        var powerCost: Int { 10 }
        func performTask() -> Int { 15 }
    }

    struct CargoDrone: FleetDrone {
        let id: String
        var chargeLevel: Int
        var powerCost: Int { 20 }
        func performTask() -> Int { 25 }
    }

    static func makeDrone(kind: String, id: String, charge: Int) -> (any FleetDrone)? {
        switch kind {
        case "welder": return WelderDrone(id: id, chargeLevel: ChargeRules.clamp(charge))
        case "scanner": return ScannerDrone(id: id, chargeLevel: ChargeRules.clamp(charge))
        case "cargo": return CargoDrone(id: id, chargeLevel: ChargeRules.clamp(charge))
        default: return nil
        }
    }

    static func runShift(_ fleet: inout [any FleetDrone], rounds: Int) -> Int {
        guard rounds > 0 else { return 0 }
        var work = 0
        for _ in 0..<rounds {
            for index in fleet.indices {
                work += fleet[index].runOnce()
            }
        }
        return work
    }
}

// The protocol extension supplies the shared shift ritual for the bonus design.
extension BonusFleetDesign.FleetDrone {
    mutating func runOnce() -> Int {
        guard chargeLevel >= powerCost else { return 0 }
        chargeLevel -= powerCost
        return performTask()
    }
}

print("\nBONUS - Protocol + struct fleet")
var bonusFleet: [any BonusFleetDesign.FleetDrone] = []
for record in fleetData {
    if let drone = BonusFleetDesign.makeDrone(kind: record.kind, id: record.id,
                                              charge: record.charge) {
        bonusFleet.append(drone)
    }
}
let bonusWork = BonusFleetDesign.runShift(&bonusFleet, rounds: 3)
print("Protocol-based fleet work after three rounds: \(bonusWork)")
for drone in bonusFleet {
    print("Bonus \(drone.id): \(drone.chargeLevel)%")
}

/*
Comparison (Bonus): A class hierarchy is convenient when every drone shares the
same reference-based battery and the runOnce ritual must never be overridden.
A protocol-based design allows value-type drones and makes standalone Drone
objects impossible. For this station I prefer the original class design because
multiple systems may need to share and observe the same mutable PowerCell; with
struct drones, their mutable state is copied and must be written back explicitly.
*/

// MARK: - ================= DEFENSE QUESTIONS =================
/*
1. Why does a class satisfy a `mutating` protocol requirement without that keyword,
   while a struct must write it?
   Classes have reference semantics: an instance method may change mutable object
   properties without rebinding self. A struct is a value type, so a method that
   changes its own stored properties must be explicitly declared `mutating`.

2. One thing inheritance does that protocols cannot, and one thing protocols do
   that inheritance cannot:
   A superclass provides inherited stored state and implementation to subclasses.
   A protocol can be adopted by both structs and classes, letting unrelated types
   share an interface and appear together in a [Diagnosable] collection.

3. What does final prevent, and what did it protect in runOnce()?
   final on a class prevents subclassing; final on a method prevents overriding.
   Drone.runOnce() is final so subclasses cannot bypass battery spending or
   accidentally perform work with insufficient charge.

4. In Report 4, why did the protocol extension's method win?
   label() was not a requirement in Labelled, so a call through a Labelled value
   used the protocol extension's statically dispatched implementation. Declaring
   label() as a protocol requirement makes the Thruster implementation dispatch
   dynamically, producing "thruster T-1".
*/
