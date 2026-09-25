// =============================================================
//  Station ALMA-7: Rescue Protocol
//  iOS Mobile Development · Module 3 · Lab Assignment
//
//  How to use:
//   • Xcode: File → New → Playground → Blank, replace everything
//     with this file's contents.
//   • Terminal: swift ALMA7_Starter.swift
//
//  Rules:
//   • Do NOT modify the STARTER CODE section.
//   • `!` (force unwrap) is forbidden: −0.5 points each.
//   • No map / filter / reduce / compactMap.
//   • Use the exact function names from the assignment PDF.
// =============================================================


// MARK: - =================== STARTER CODE ===================
// MARK: - Do not modify anything in this section

typealias Reading = (sensor: String, value: Int)

/// Splits a string at the first occurrence of the separator.
/// splitOnce("O2:87", by: ":") -> ("O2", "87")
/// splitOnce("hello", by: ":") -> nil
func splitOnce(_ line: String, by separator: Character) -> (String, String)? {
    guard let index = line.firstIndex(of: separator) else { return nil }
    let left = String(line[..<index])
    let right = String(line[line.index(after: index)...])
    return (left, right)
}

let rawLog = [
    "O2:87", "TEMP:-12", "O2:9x", "PRESS:101", "TEMP:abc", "O2:",
    "RAD:3", "O2:64", ":55", "TEMP:31", "PRESS:98", "O2:71",
    "RAD:-1", "TEMP:4", "PRESS:1o2", "O2:90"
]

class Tank {
    var level: Int
    init(level: Int) { self.level = level }
}

class Module {
    let name: String
    var oxygenTank: Tank?
    init(name: String, oxygenTank: Tank?) {
        self.name = name
        self.oxygenTank = oxygenTank
    }
}

class CrewMember {
    let name: String
    let role: String
    let priority: Int      // 1 = evacuated first
    var module: Module?    // nil = in open space
    init(name: String, role: String, priority: Int, module: Module?) {
        self.name = name
        self.role = role
        self.priority = priority
        self.module = module
    }
}

let lab  = Module(name: "Lab",  oxygenTank: Tank(level: 40))
let hab  = Module(name: "Hab",  oxygenTank: Tank(level: 12))
let dock = Module(name: "Dock", oxygenTank: nil)

let crew = [
    CrewMember(name: "Timur",   role: "Engineer",  priority: 3, module: lab),
    CrewMember(name: "Dana",    role: "Scientist", priority: 4, module: dock),
    CrewMember(name: "Aigerim", role: "Commander", priority: 1, module: hab),
    CrewMember(name: "Nurlan",  role: "Pilot",     priority: 2, module: nil)
]

var roster: [String: CrewMember] = [:]
for member in crew { roster[member.name] = member }

print("ALMA-7 systems online: \(rawLog.count) log lines, \(crew.count) crew members.")

// MARK: - ================= END OF STARTER CODE =================


// MARK: - =================== YOUR SOLUTION ===================


// MARK: Level 1 · Decoding Telemetry

// 1.1
func parseReading(_ raw: String) -> Reading? {
    guard let parts = splitOnce(raw, by: ":"),
          !parts.0.isEmpty,
          let value = Int(parts.1),
          value >= 0 || parts.0 == "TEMP" else {
        return nil
    }
    return (sensor: parts.0, value: value)
}

print("1.1 test 1:", parseReading("O2:87") as Any)
print("1.1 test 2:", parseReading("TEMP:-12") as Any)
print("1.1 test 3:", parseReading("RAD:-1") as Any)
print("1.1 test 4:", parseReading(":55") as Any)

// 1.2
func parseLog(_ lines: [String]) -> (valid: [Reading], invalidCount: Int) {
    var valid: [Reading] = []
    var invalidCount = 0

    for line in lines {
        if let reading = parseReading(line) {
            valid.append(reading)
        } else {
            invalidCount += 1
        }
    }

    return (valid, invalidCount)
}

let parsedLog = parseLog(rawLog)
let validReadings = parsedLog.valid
let A = parsedLog.invalidCount
print("1.2 test 1: valid = \(validReadings.count), invalid = \(A)")
let smallLogTest = parseLog(["O2:10", "BAD", "TEMP:-5"])
print("1.2 test 2: valid = \(smallLogTest.valid.count), invalid = \(smallLogTest.invalidCount)")


// MARK: Level 2 · Analysis

// 2.1
func select(_ readings: [Reading], where isIncluded: (Reading) -> Bool) -> [Reading] {
    var result: [Reading] = []

    for reading in readings {
        if isIncluded(reading) {
            result.append(reading)
        }
    }

    return result
}

func values(of readings: [Reading]) -> [Int] {
    var result: [Int] = []

    for reading in readings {
        result.append(reading.value)
    }

    return result
}

let o2Readings = select(validReadings) { $0.sensor == "O2" }
print("2.1 select test 1:", o2Readings)
let tempReadingsForTest = select(validReadings) { $0.sensor == "TEMP" }
print("2.1 select test 2:", tempReadingsForTest)
print("2.1 values test 1:", values(of: o2Readings))
print("2.1 values test 2:", values(of: tempReadingsForTest))

// 2.2
func stats(of values: [Int]) -> (min: Int, max: Int, average: Double)? {
    guard let first = values.first else { return nil }

    var minimum = first
    var maximum = first
    var total = 0

    for value in values {
        if value < minimum {
            minimum = value
        }
        if value > maximum {
            maximum = value
        }
        total += value
    }

    let average = Double(total) / Double(values.count)
    return (minimum, maximum, average)
}

func stats(_ values: Int...) -> (min: Int, max: Int, average: Double)? { stats(of: values) }

print("2.2 array stats test 1:", stats(of: [3, 8, 1]) as Any)
print("2.2 array stats test 2:", stats(of: []) as Any)
print("2.2 variadic stats test 1:", stats(3, 8, 1) as Any)
print("2.2 variadic stats test 2:", stats() as Any)

let o2Values = values(of: o2Readings)
let B = Int(stats(of: o2Values)?.average ?? 0)
print("B =", B)

// 2.3 · The Closure Ladder
let sorted1 = validReadings.sorted(by: { (left: Reading, right: Reading) -> Bool in
    return left.value > right.value
})

let sorted2 = validReadings.sorted(by: { left, right in
    return left.value > right.value
})

let sorted3 = validReadings.sorted(by: { left, right in
    left.value > right.value
})

let sorted4 = validReadings.sorted(by: { $0.value > $1.value })

let sorted5 = validReadings.sorted { $0.value > $1.value }

var allSortsMatch = true
for index in validReadings.indices {
    let reference = sorted1[index]
    let candidates = [sorted2[index], sorted3[index], sorted4[index], sorted5[index]]
    for candidate in candidates {
        if candidate.sensor != reference.sensor || candidate.value != reference.value {
            allSortsMatch = false
        }
    }
}

print("2.3 sort test 1:", sorted1)
print("2.3 sort test 2, all five match:", allSortsMatch)


// MARK: Level 3 · Temperature Stabilization

// 3.1
func heatUp(_ t: Int) -> Int {
    t + 5
}

func coolDown(_ t: Int) -> Int {
    t - 3
}

func hold(_ t: Int) -> Int {
    t
}

func chooseProtocol(for temp: Int) -> (Int) -> Int {
    if temp < 18 {
        return heatUp
    } else if temp > 24 {
        return coolDown
    } else {
        return hold
    }
}

print("3.1 heatUp tests:", heatUp(10), heatUp(17))
print("3.1 coolDown tests:", coolDown(30), coolDown(25))
print("3.1 hold tests:", hold(20), hold(24))
print("3.1 chooseProtocol test 1:", chooseProtocol(for: 10)(10))
print("3.1 chooseProtocol test 2:", chooseProtocol(for: 30)(30))

// 3.2
func runUntilStable(from start: Int, maxSteps: Int = 10) -> (finalTemp: Int, steps: Int, isStable: Bool) {
    var temperature = start
    var steps = 0

    while !(18...24).contains(temperature) && steps < maxSteps {
        let protocolFunction = chooseProtocol(for: temperature)
        temperature = protocolFunction(temperature)
        steps += 1
    }

    return (temperature, steps, (18...24).contains(temperature))
}

print("3.2 test 1:", runUntilStable(from: 31))
print("3.2 test 2:", runUntilStable(from: -100, maxSteps: 5))

let tempReadings = select(validReadings) { $0.sensor == "TEMP" }
let tempValues = values(of: tempReadings)
let lowestTemperature = stats(of: tempValues)?.min ?? 0
let C = runUntilStable(from: lowestTemperature).steps
print("C =", C)


// MARK: Level 4 · The Crew

// 4.1
func oxygenLevel(of member: CrewMember) -> Int? { member.module?.oxygenTank?.level }

print("4.1 test 1:", oxygenLevel(of: crew[0]) as Any)
print("4.1 test 2:", oxygenLevel(of: crew[1]) as Any)

// 4.2
func status(of member: CrewMember) -> String {
    let location = member.module?.name ?? "open space"

    guard let level = oxygenLevel(of: member) else {
        return "\(member.name): no data (\(location))"
    }

    let condition = level < 20 ? "CRITICAL" : "OK"
    return "\(member.name): \(level)% \(condition)"
}

print("4.2 test 1:", status(of: crew[0]))
print("4.2 test 2:", status(of: crew[2]))
print("4.2 whole crew:")
for member in crew {
    print(status(of: member))
}

// 4.3
@discardableResult
func transferOxygen(from source: inout Int, to target: inout Int, amount: Int) -> Int {
    guard amount > 0 else { return 0 }

    let freeSpace = 100 - target
    let transferable = Swift.min(amount, source, freeSpace)

    guard transferable > 0 else { return 0 }

    source -= transferable
    target += transferable
    return transferable
}

var testSource1 = 20
var testTarget1 = 95
let testMoved1 = transferOxygen(from: &testSource1, to: &testTarget1, amount: 20)
print("4.3 test 1: moved = \(testMoved1), source = \(testSource1), target = \(testTarget1)")

var testSource2 = 20
var testTarget2 = 10
let testMoved2 = transferOxygen(from: &testSource2, to: &testTarget2, amount: -5)
print("4.3 test 2: moved = \(testMoved2), source = \(testSource2), target = \(testTarget2)")

if let labTank = lab.oxygenTank, let habTank = hab.oxygenTank {
    let moved = transferOxygen(from: &labTank.level, to: &habTank.level, amount: 30)
    print("4.3 Lab -> Hab transferred:", moved)
}

let D = hab.oxygenTank?.level ?? 0
print("D =", D)

// 4.4
func evacuationOrder(_ names: String..., roster: [String: CrewMember]) -> [String] {
    var found: [CrewMember] = []

    for name in names {
        guard let member = roster[name] else {
            print("Unknown crew member: \(name)")
            continue
        }
        found.append(member)
    }

    found.sort { $0.priority < $1.priority }

    var orderedNames: [String] = []
    for member in found {
        orderedNames.append(member.name)
    }
    return orderedNames
}

print("4.4 test 1:", evacuationOrder("Dana", "Ghost", "Aigerim", "Timur", roster: roster))
print("4.4 test 2:", evacuationOrder("Nurlan", "Aigerim", roster: roster))


// MARK: Level 5 · The Saboteur's Logbook
/*
 Problems in the original reportOxygen:
 - member.module! crashes when the crew member has no module, for example Nurlan.
 - oxygenTank! crashes when the module exists but has no tank, for example Dana in Dock.
 - Both force unwraps are unsafe and are forbidden by the assignment rules.

 Problems in the original firstCritical:
 - oxygenLevel(of: member)! crashes when oxygen data is missing, for example Dana or Nurlan.
 - The loop keeps replacing result, so with several critical crew members it returns the LAST one, not the first one.
 - result! crashes if nobody is critical, or if the crew array is empty.
 - Returning String does not allow the function to represent the valid case where no critical member exists.
*/

func reportOxygen(for member: CrewMember) -> String {
    guard let level = oxygenLevel(of: member) else {
        return "\(member.name): no data"
    }
    return "\(member.name): \(level)%"
}

func firstCritical(in crew: [CrewMember]) -> String? {
    for member in crew {
        guard let level = oxygenLevel(of: member) else {
            continue
        }

        if level < 20 {
            return member.name
        }
    }
    return nil
}

print("5 report test 1:", reportOxygen(for: crew[0]))
print("5 report test 2:", reportOxygen(for: crew[1]))
print("5 firstCritical test 1:", firstCritical(in: crew) ?? "none")
print("5 firstCritical test 2:", firstCritical(in: []) ?? "none")

let criticalModule1 = Module(name: "Test-1", oxygenTank: Tank(level: 10))
let criticalModule2 = Module(name: "Test-2", oxygenTank: Tank(level: 5))
let firstCriticalMember = CrewMember(name: "First", role: "Tester", priority: 1, module: criticalModule1)
let secondCriticalMember = CrewMember(name: "Second", role: "Tester", priority: 2, module: criticalModule2)
let logicBugTestCrew = [firstCriticalMember, secondCriticalMember]
print("5 logic bug proof, expected First:", firstCritical(in: logicBugTestCrew) ?? "none")


// MARK: Finale · Launch Code

let launchCode = "\(A)-\(B)-\(C)-\(D)"
print("LAUNCH CODE: \(launchCode)")


// MARK: Bonus

func makeAlarm(threshold: Int) -> (Int) -> Bool {
    var count = 0

    return { level in
        if level < threshold {
            count += 1
            print("Alarm #\(count)")
            return true
        }
        return false
    }
}

let alarm = makeAlarm(threshold: 20)
let secondAlarm = makeAlarm(threshold: 50)
print("Bonus test 1:", alarm(12))
print("Bonus test 2:", alarm(40))
print("Bonus test 3:", alarm(5))
print("Bonus second makeAlarm call:", secondAlarm(45))


// MARK: - ================= DEFENSE QUESTIONS =================
/*
 1. guard let vs if let beyond syntax:
 guard let is useful when the function cannot continue without a value. It exits early and keeps the unwrapped value available after the guard block. With if let, the rest of the function can become deeply nested.
 Example: in status(of:), if there is no oxygen level, we return immediately instead of putting the whole normal path inside an if block.

 2. Why can't you pass [Int] to stats(_ values: Int...)?
 A variadic parameter accepts separate Int arguments at the call site, such as stats(3, 8, 1). An [Int] is one array value, not several separate Int arguments. For an array, the correct overload is stats(of: someArray).

 3. Why doesn't transferOxygen(from: &x, to: &x, amount: 5) compile?
 Both parameters are inout, so they need exclusive write access while the function runs. Passing the same variable twice would create overlapping writes to x. Swift blocks this to prevent conflicting mutations and unpredictable results.

 4. Why doesn't oxygenLevel(of: dana) ?? "no data" compile?
 oxygenLevel returns Int?. The ?? operator needs a fallback value compatible with Int, but "no data" is a String. The two sides have different types.

 5. Full type of chooseProtocol and how to read it:
 (Int) -> (Int) -> Int
 It means chooseProtocol takes one Int and returns another function. That returned function takes an Int and returns an Int.

 Bonus. Where does the alarm counter live after makeAlarm returns?
 The returned closure captures count in its closure context. That captured storage stays alive as long as the closure exists, so later calls to the same alarm closure keep using and changing the same counter.
*/
