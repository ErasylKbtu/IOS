// =============================================================
//  Station ALMA-7, Part II: The Teleporter Incident
//  iOS Mobile Development · Module 4 · Lab Assignment
// =============================================================


// MARK: - =================== STARTER DATA ===================
// MARK: - Do not modify anything in this section

/// Splits a line into fields.
/// fields("crate:101:120")            -> ["crate", "101", "120"]
/// fields("livestock:lab mice:12:2")  -> ["livestock", "lab mice", "12", "2"]
/// fields("junk")                     -> ["junk"]
func fields(_ line: String, separatedBy separator: Character = ":") -> [String] {
    var result: [String] = []
    var current = ""
    for character in line {
        if character == separator {
            result.append(current)
            current = ""
        } else {
            current.append(character)
        }
    }
    result.append(current)
    return result
}

/// Cargo manifest as recovered from the damaged recorder.
let rawManifest = [
    "crate:101:120",
    "container:KZ-ALM-7:340",
    "livestock:lab mice:12:2",
    "???-corrupted-line",
    "crate:102:75",
    "container:KZ-ALM-9:410",
    "livestock:ficus:3:5",
    "crate:103:260",
    "crate:104:abc",
    ""
]

/// Oxygen readings. One of these deck names is not a real deck.
let deckReadings: [(deck: String, oxygen: Int)] = [
    (deck: "bridge",     oxygen: 78),
    (deck: "lab",        oxygen: 64),
    (deck: "greenhouse", oxygen: 55),
    (deck: "cargo",      oxygen: 12),
    (deck: "medbay",     oxygen: 90),
    (deck: "engine",     oxygen: 41)
]

/// Crew records, straight from the personnel file.
let crewData: [(name: String, deck: String, oxygen: Int)] = [
    (name: "Timur",   deck: "engine", oxygen: 62),
    (name: "Dana",    deck: "lab",    oxygen: 48),
    (name: "Aigerim", deck: "bridge", oxygen: 91),
    (name: "Nurlan",  deck: "cargo",  oxygen: 17)
]

print("ALMA-7 recorder online: \(rawManifest.count) manifest lines, \(deckReadings.count) readings, \(crewData.count) crew records.")

// MARK: - ================= END OF STARTER DATA =================


// MARK: - =================== YOUR SOLUTION ===================


// MARK: Level 1 · The Deck Register

// 1.1

enum Deck: String, CaseIterable {
    case bridge
    case lab
    case cargo
    case medbay
    case engine

    var evacuationPriority: Int {
        switch self {
        case .bridge:
            return 1
        case .medbay:
            return 2
        case .lab:
            return 3
        case .engine:
            return 4
        case .cargo:
            return 5
        }
    }
}

print("\nLEVEL 1.1 — Deck register")
for deck in Deck.allCases {
    print("Deck \(deck.rawValue), evacuation priority: \(deck.evacuationPriority)")
}

// Extra print to exercise Deck directly.
print("Bridge raw value: \(Deck.bridge.rawValue)")


// 1.2

enum AlarmLevel: Int {
    case green = 0
    case yellow
    case orange
    case red

    static func level(forTotalMass mass: Int) -> AlarmLevel {
        let safeMass = max(0, mass)
        let rawLevel = min(safeMass / 500, AlarmLevel.red.rawValue)

        guard let level = AlarmLevel(rawValue: rawLevel) else {
            return .red
        }

        return level
    }
}

print("\nLEVEL 1.2 — Alarm levels")
print("Mass 0 kg -> alarm raw value \(AlarmLevel.level(forTotalMass: 0).rawValue)")
print("Mass 940 kg -> alarm raw value \(AlarmLevel.level(forTotalMass: 940).rawValue)")
print("Mass 4000 kg -> alarm raw value \(AlarmLevel.level(forTotalMass: 4000).rawValue)")


// MARK: Level 2 · The Manifest

// 2.1

enum ManifestEntry {
    case crate(id: Int, massKg: Int)
    case container(code: String, massKg: Int)
    case livestock(species: String, count: Int, massPerUnitKg: Int)
    case unknown(raw: String)
}

// 2.2

func parseEntry(_ line: String) -> ManifestEntry {
    let parts = fields(line)

    guard !parts.isEmpty else {
        return .unknown(raw: line)
    }

    switch parts[0] {
    case "crate":
        guard parts.count == 3,
              let id = Int(parts[1]),
              let massKg = Int(parts[2]) else {
            return .unknown(raw: line)
        }
        return .crate(id: id, massKg: massKg)

    case "container":
        guard parts.count == 3,
              let massKg = Int(parts[2]) else {
            return .unknown(raw: line)
        }
        return .container(code: parts[1], massKg: massKg)

    case "livestock":
        guard parts.count == 4,
              let count = Int(parts[2]),
              let massPerUnitKg = Int(parts[3]) else {
            return .unknown(raw: line)
        }
        return .livestock(
            species: parts[1],
            count: count,
            massPerUnitKg: massPerUnitKg
        )

    default:
        return .unknown(raw: line)
    }
}

// 2.3

func mass(of entry: ManifestEntry) -> Int {
    switch entry {
    case let .crate(_, massKg):
        return massKg

    case let .container(_, massKg):
        return massKg

    case let .livestock(_, count, massPerUnitKg):
        return count * massPerUnitKg

    case .unknown:
        return 0
    }
}

print("\nLEVEL 2 — Manifest")

var manifestEntries: [ManifestEntry] = []
var totalManifestMass = 0
var unknownCount = 0

for line in rawManifest {
    let entry = parseEntry(line)
    manifestEntries.append(entry)
    totalManifestMass += mass(of: entry)

    switch entry {
    case let .crate(id, massKg):
        print("Crate id=\(id), mass=\(massKg) kg")

    case let .container(code, massKg):
        print("Container \(code), mass=\(massKg) kg")

    case let .livestock(species, count, massPerUnitKg):
        print("Livestock \(species), count=\(count), each=\(massPerUnitKg) kg")

    case let .unknown(raw):
        unknownCount += 1
        print("Unknown/corrupted entry: \(raw)")
    }
}

print("Unknown manifest lines: \(unknownCount)")
print("Total manifest mass: \(totalManifestMass) kg")

let A = totalManifestMass


// MARK: Level 3 · Crew Snapshots

// 3.1

struct CrewSnapshot {
    let name: String
    var deck: Deck
    var oxygen: Int

    mutating func breathe(_ amount: Int) {
        oxygen = max(0, oxygen - max(0, amount))
    }

    mutating func move(to deck: Deck) {
        self.deck = deck
    }

    mutating func reviveInMedbay() {
        self = CrewSnapshot(name: name, deck: .medbay, oxygen: 100)
    }

    static func rookie(named name: String) -> CrewSnapshot {
        CrewSnapshot(name: name, deck: .bridge, oxygen: 100)
    }
}

// 3.2

var builtRoster: [CrewSnapshot] = []

print("\nLEVEL 3.2 — Building crew roster")
for record in crewData {
    guard let deck = Deck(rawValue: record.deck) else {
        print("Warning: invalid deck '\(record.deck)' for \(record.name). Record skipped.")
        continue
    }

    let crew = CrewSnapshot(
        name: record.name,
        deck: deck,
        oxygen: record.oxygen
    )
    builtRoster.append(crew)
}

let crewRoster: [CrewSnapshot] = builtRoster

for member in crewRoster {
    print("\(member.name): deck=\(member.deck.rawValue), oxygen=\(member.oxygen)")
}

print("Crew roster count: \(crewRoster.count)")

// Helper to find a crew member without using map/filter/compactMap.
func crewMember(named name: String, in roster: [CrewSnapshot]) -> CrewSnapshot? {
    for member in roster {
        if member.name == name {
            return member
        }
    }
    return nil
}

// 3.3 · Value-semantics demonstration (copy / plain parameter / inout)

print("\nLEVEL 3.3 — Value semantics")

var originalSnapshot = CrewSnapshot.rookie(named: "Value Demo")
print("Copy test BEFORE: original oxygen = \(originalSnapshot.oxygen)")

var copiedSnapshot = originalSnapshot
copiedSnapshot.breathe(25)
print("Copy test AFTER: original oxygen = \(originalSnapshot.oxygen), copy oxygen = \(copiedSnapshot.oxygen)")

func changedCopy(_ snapshot: CrewSnapshot) -> CrewSnapshot {
    var localCopy = snapshot
    localCopy.breathe(15)
    localCopy.move(to: .lab)
    return localCopy
}

print("Plain parameter BEFORE: original deck = \(originalSnapshot.deck.rawValue), oxygen = \(originalSnapshot.oxygen)")
let plainResult = changedCopy(originalSnapshot)
print("Plain parameter AFTER: original deck = \(originalSnapshot.deck.rawValue), oxygen = \(originalSnapshot.oxygen); returned copy deck = \(plainResult.deck.rawValue), oxygen = \(plainResult.oxygen)")

func changeInPlace(_ snapshot: inout CrewSnapshot) {
    snapshot.breathe(10)
    snapshot.move(to: .engine)
}

print("inout BEFORE: original deck = \(originalSnapshot.deck.rawValue), oxygen = \(originalSnapshot.oxygen)")
changeInPlace(&originalSnapshot)
print("inout AFTER: original deck = \(originalSnapshot.deck.rawValue), oxygen = \(originalSnapshot.oxygen)")

var revivedSnapshot = originalSnapshot
print("Revive BEFORE: deck = \(revivedSnapshot.deck.rawValue), oxygen = \(revivedSnapshot.oxygen)")
revivedSnapshot.reviveInMedbay()
print("Revive AFTER: deck = \(revivedSnapshot.deck.rawValue), oxygen = \(revivedSnapshot.oxygen)")


// MARK: Level 4 · The Teleport Pod

// 4.1

final class TeleportPod {
    let id: String
    var chargeLevel: Int
    var occupant: CrewSnapshot?

    // Classes do not receive the same automatic memberwise initializer that structs do,
    // so this initializer is written explicitly.
    init(id: String, chargeLevel: Int) {
        self.id = id
        self.chargeLevel = chargeLevel
        self.occupant = nil
    }

    func load(_ crew: CrewSnapshot) -> Bool {
        guard occupant == nil, chargeLevel >= 20 else {
            return false
        }

        occupant = crew
        return true
    }

    func fire() -> CrewSnapshot? {
        guard let crew = occupant else {
            return nil
        }

        occupant = nil
        chargeLevel -= 20
        return crew
    }

    deinit {
        print("TeleportPod \(id) deinitialized")
    }
}

// 4.2 · Charge ledger: load+fire three times, then fire an empty pod

print("\nLEVEL 4.2 — Teleport pod charge ledger")

let mainPod = TeleportPod(id: "P-1", chargeLevel: 100)
print("Initial charge: \(mainPod.chargeLevel)")

if let timur = crewMember(named: "Timur", in: crewRoster) {
    let loaded = mainPod.load(timur)
    print("Load Timur: \(loaded), charge = \(mainPod.chargeLevel)")
    let fired = mainPod.fire()
    print("Fire Timur: \(fired != nil), charge = \(mainPod.chargeLevel)")
}

if let dana = crewMember(named: "Dana", in: crewRoster) {
    let loaded = mainPod.load(dana)
    print("Load Dana: \(loaded), charge = \(mainPod.chargeLevel)")
    let fired = mainPod.fire()
    print("Fire Dana: \(fired != nil), charge = \(mainPod.chargeLevel)")
}

if let nurlan = crewMember(named: "Nurlan", in: crewRoster) {
    let loaded = mainPod.load(nurlan)
    print("Load Nurlan: \(loaded), charge = \(mainPod.chargeLevel)")
    let fired = mainPod.fire()
    print("Fire Nurlan: \(fired != nil), charge = \(mainPod.chargeLevel)")
}

let emptyFire = mainPod.fire()
print("Fire empty pod: \(emptyFire != nil), charge = \(mainPod.chargeLevel)")

let C = mainPod.chargeLevel

// 4.3 · Reference-semantics demonstration

print("\nLEVEL 4.3 — Reference semantics")

let podReferenceA = mainPod
let podReferenceB = podReferenceA

print("Class BEFORE: A charge = \(podReferenceA.chargeLevel), B charge = \(podReferenceB.chargeLevel)")
podReferenceB.chargeLevel = 35
print("Class AFTER: A charge = \(podReferenceA.chargeLevel), B charge = \(podReferenceB.chargeLevel)")

var structValueA = CrewSnapshot.rookie(named: "Struct Demo")
var structValueB = structValueA

print("Struct BEFORE: A oxygen = \(structValueA.oxygen), B oxygen = \(structValueB.oxygen)")
structValueB.breathe(30)
print("Struct AFTER: A oxygen = \(structValueA.oxygen), B oxygen = \(structValueB.oxygen)")

// Rule: class assignment copies a reference to the same object, while struct assignment copies the value.


// MARK: Level 5 · Station Systems

// 5.1

final class Station {
    let callSign: String

    var hullIntegrity: Int {
        willSet {
            print("Hull integrity will change from \(hullIntegrity) to \(newValue)")
        }
        didSet {
            if hullIntegrity > 100 {
                hullIntegrity = 100
            } else if hullIntegrity < 0 {
                hullIntegrity = 0
            }
        }
    }

    var oxygenByDeck: [Deck: Int]

    lazy var fullDiagnostics: String = {
        print("Running full scan...")
        return "Station \(callSign): hull=\(hullIntegrity), decks=\(oxygenByDeck.count), total oxygen=\(totalOxygen)"
    }()

    var totalOxygen: Int {
        var total = 0
        for oxygen in oxygenByDeck.values {
            total += oxygen
        }
        return total
    }

    var averageOxygen: Int {
        get {
            guard !oxygenByDeck.isEmpty else {
                return 0
            }
            return totalOxygen / oxygenByDeck.count
        }
        set {
            var decks: [Deck] = []
            for deck in oxygenByDeck.keys {
                decks.append(deck)
            }

            for deck in decks {
                oxygenByDeck[deck] = newValue
            }
        }
    }

    init(callSign: String, hullIntegrity: Int, readings: [(deck: String, oxygen: Int)]) {
        self.callSign = callSign
        self.hullIntegrity = hullIntegrity
        self.oxygenByDeck = [:]

        for reading in readings {
            guard let deck = Deck(rawValue: reading.deck) else {
                print("Warning: oxygen reading for unknown deck '\(reading.deck)' skipped.")
                continue
            }
            self.oxygenByDeck[deck] = reading.oxygen
        }
    }
}

print("\nLEVEL 5.1 — Station systems")

let station = Station(callSign: "ALMA-7", hullIntegrity: 100, readings: deckReadings)
print("Station created: \(station.callSign), valid oxygen decks = \(station.oxygenByDeck.count)")
print("Starting total oxygen: \(station.totalOxygen)")
print("Starting average oxygen: \(station.averageOxygen)")

let B = station.averageOxygen

print("Diagnostics have not been accessed yet.")
print("First diagnostics access: \(station.fullDiagnostics)")
print("Second diagnostics access: \(station.fullDiagnostics)")

let stationWithoutScan = Station(callSign: "ALMA-7-BACKUP", hullIntegrity: 90, readings: deckReadings)
print("Backup station created: \(stationWithoutScan.callSign)")
print("Backup station diagnostics are never accessed, so its full scan does not run.")

print("Average oxygen BEFORE setter: \(station.averageOxygen)")
station.averageOxygen = 50
print("Average oxygen AFTER setter: \(station.averageOxygen)")
print("Total oxygen AFTER setter: \(station.totalOxygen)")

// 5.2 · The clamp trap: 130, then -40, then 55

print("\nLEVEL 5.2 — Hull clamp")

station.hullIntegrity = 130
print("After assigning 130: \(station.hullIntegrity)")

station.hullIntegrity = -40
print("After assigning -40: \(station.hullIntegrity)")

station.hullIntegrity = 55
print("After assigning 55: \(station.hullIntegrity)")

// Assigning hullIntegrity inside didSet does not call the observers again,
// so clamping the property inside didSet does not create an infinite loop.


// MARK: Level 6 · Incident Reports

print("\nLEVEL 6 — Incident Reports")

/*
 Report 1

 Expected:
 The author expected every member in roster to lose 10 oxygen.

 Actual:
 `member` is a separate copy of each CrewSnapshot because CrewSnapshot is a struct.
 Changing member does not change the element stored in roster.

 Rule:
 Structs have value semantics. The for-in loop gives us a value copy here.

 Fix:
 Change the array element through its index.
*/

var report1Roster = crewRoster
print("Report 1 fix BEFORE: first oxygen = \(report1Roster[0].oxygen)")
for index in report1Roster.indices {
    report1Roster[index].oxygen = max(0, report1Roster[index].oxygen - 10)
}
print("Report 1 fix AFTER: first oxygen = \(report1Roster[0].oxygen)")

/*
 Report 2

 Expected:
 The author expected podA to stay at charge 100 after changing podB.

 Actual:
 podA and podB refer to the same TeleportPod object, so changing podB also changes
 what we observe through podA.

 Rule:
 Classes have reference semantics.

 Fix:
 If two independent pods are needed, create two separate TeleportPod instances.
*/

let report2PodA = TeleportPod(id: "A", chargeLevel: 100)
let report2PodB = TeleportPod(id: "A-copy", chargeLevel: 100)
print("Report 2 fix BEFORE: A = \(report2PodA.chargeLevel), B = \(report2PodB.chargeLevel)")
report2PodB.chargeLevel = 0
print("Report 2 fix AFTER: A = \(report2PodA.chargeLevel), B = \(report2PodB.chargeLevel)")

/*
 Report 3

 Expected:
 The author expected add(_:) to append a new string to entries.

 Actual:
 It does not compile because a normal struct instance method cannot mutate self.
 The compiler reports that self is immutable and suggests marking the method mutating.

 Rule:
 A struct method that changes a stored property must be marked `mutating`.

 Fixed version:

 struct Logbook {
     var entries: [String] = []

     mutating func add(_ entry: String) {
         entries.append(entry)
     }
 }
*/

/*
 Report 4

 Expected:
 The author expected both property assignments to work even though snapshot and pod
 were declared with let.

 Actual:
 `snapshot.oxygen = 40` does not compile. CrewSnapshot is a struct, and let freezes
 the whole stored value. `pod.chargeLevel = 10` does compile because pod is a class;
 let freezes the reference, not the mutable properties of the referenced object.

 Rule:
 let + struct makes the value immutable. let + class prevents assigning a different
 object to the variable, but mutable var properties of the same object may still change.

 Fix:
 Declare the snapshot with var. The pod can stay let.
*/

var report4Snapshot = CrewSnapshot.rookie(named: "Dana")
let report4Pod = TeleportPod(id: "B", chargeLevel: 50)
print("Report 4 fix BEFORE: snapshot oxygen = \(report4Snapshot.oxygen), pod charge = \(report4Pod.chargeLevel)")
report4Snapshot.oxygen = 40
report4Pod.chargeLevel = 10
print("Report 4 fix AFTER: snapshot oxygen = \(report4Snapshot.oxygen), pod charge = \(report4Pod.chargeLevel)")


// MARK: Level 7 · Sealing the Black Box

final class FlightRecorder {
    // private blocks outside code from directly replacing, clearing, or appending to the stored history.
    private var entries: [String] = []

    // private(set) lets outside code read the sealed state but blocks outside code from changing it.
    private(set) var isSealed = false

    var entryCount: Int {
        entries.count
    }

    var transcript: String {
        if entries.isEmpty {
            return "No entries"
        }

        var result = ""
        var number = 1

        for entry in entries {
            if !result.isEmpty {
                result += "\n"
            }
            result += "\(number). \(entry)"
            number += 1
        }

        return result
    }

    @discardableResult
    func add(_ entry: String) -> Bool {
        guard !isSealed else {
            return false
        }

        entries.append(entry)
        return true
    }

    func seal() {
        isSealed = true
    }

    // fileprivate allows the free audit function in this file to use this helper, while other files cannot.
    fileprivate func auditSummary() -> String {
        "Recorder sealed=\(isSealed), entries=\(entries.count)\n\(transcript)"
    }
}

// A free function elsewhere in the file that uses the fileprivate helper.
func auditTranscript(of recorder: FlightRecorder) -> String {
    recorder.auditSummary()
}

print("\nLEVEL 7 — Flight recorder")

let recorder = FlightRecorder()
print("Recorder at start: count = \(recorder.entryCount), sealed = \(recorder.isSealed)")

print("Add first entry: \(recorder.add("Teleporter online"))")
print("Add second entry: \(recorder.add("Manifest verified"))")
print("Transcript before seal:\n\(recorder.transcript)")

recorder.seal()
print("Recorder after seal: count = \(recorder.entryCount), sealed = \(recorder.isSealed)")
print("Try to add after seal: \(recorder.add("This must not be added"))")
print("Audit transcript:\n\(auditTranscript(of: recorder))")

// Failed attempts from outside the type:
// recorder.entries.removeAll()
// Compiler error: 'entries' is inaccessible due to 'private' protection level.

// recorder.isSealed = false
// Compiler error: setter for 'isSealed' is inaccessible due to 'private' protection level.


// MARK: Finale · Integrity Code

let D = AlarmLevel.level(forTotalMass: A).rawValue
let integrityCode = "\(A)-\(B)-\(C)-\(D)"
print("\nINTEGRITY CODE: \(integrityCode)")


// MARK: Bonus (+1)

print("\nBONUS — deinit, reference counting, and identity")

var bonusReference: TeleportPod?
do {
    let localPod = TeleportPod(id: "BONUS-1", chargeLevel: 60)
    bonusReference = localPod
    print("Inside do block: BONUS-1 has a second strong reference.")
    print("Same object inside block: \(localPod === bonusReference)")
}

print("After leaving do block: the pod is still alive because bonusReference keeps it.")
bonusReference = nil
print("After bonusReference = nil: the last strong reference is gone.")

func areSamePod(_ first: TeleportPod, _ second: TeleportPod) -> Bool {
    first === second
}

let identityPodA = TeleportPod(id: "IDENTITY", chargeLevel: 50)
let identityPodAlias = identityPodA
let identityPodB = TeleportPod(id: "IDENTITY", chargeLevel: 50)

print("A and alias are the same object: \(areSamePod(identityPodA, identityPodAlias))")
print("A and B have equal-looking contents but are the same object: \(areSamePod(identityPodA, identityPodB))")

// === cannot be used with CrewSnapshot because CrewSnapshot is a struct value,
// not a class reference with object identity.


// MARK: - ================= DEFENSE QUESTIONS =================
/*
 1. Why did CrewSnapshot get an initializer for free while TeleportPod did not?

 CrewSnapshot is a struct, so Swift automatically gives it a memberwise initializer
 because its stored properties do not already have a custom initializer that removes it.
 Classes do not get the same automatic memberwise initializer, so TeleportPod needs an
 explicit init(id:chargeLevel:) that initializes all of its stored properties.

 2. What does `mutating` actually do to self, and why do classes never need it?

 A normal struct method treats self as immutable. Marking the method `mutating` allows
 the method to change stored properties or even replace self with a new struct value.
 Classes are reference types, so their instance methods can change var properties of the
 referenced object without the mutating keyword.

 3. In Report 4, both values are declared with let. What exactly does let freeze for a
 struct, and what does it freeze for a class?

 For a struct, let freezes the complete value, so its var properties cannot be changed.
 For a class, let freezes only the reference stored in the variable. The variable cannot
 be redirected to another object, but var properties of the same object can still change.

 4. Why must a lazy property be var? When does lazy change behaviour, not just performance?

 A lazy property receives its first value after the object has already been initialized.
 That means the stored property changes from "not initialized yet" to its real value on
 first access, so it must be var. Lazy changes behaviour when creating the value has a
 visible side effect. In Station, accessing fullDiagnostics prints "Running full scan...".
 If it is never accessed, that scan and print never happen at all.

 5. private vs fileprivate: where in your FlightRecorder would private be too strict?

 The stored entries should be private because only FlightRecorder itself should directly
 change them. The auditSummary() helper is fileprivate because auditTranscript(of:) is a
 free function outside the class but in the same source file. If auditSummary() were
 private, that free function could not call it.

 Bonus. On which line does deinit fire, and why can't === be used on CrewSnapshot?

 In the bonus experiment, deinit fires when `bonusReference = nil` removes the final
 strong reference to BONUS-1. Leaving the do block alone is not enough because the second
 reference still owns the object. The === operator works only with class references
 because it checks whether two references identify the exact same object. CrewSnapshot
 is a struct value, so it has no object identity for === to compare.
*/
