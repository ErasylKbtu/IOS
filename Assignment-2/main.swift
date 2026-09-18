import Foundation

print("=== Easy Tasks ===")

// 1. Array Creation and Access
var fruits = ["Apple", "Banana", "Orange", "Mango", "Grapes"]
print("1. Third fruit:", fruits[2])

// 2. Set Creation and Manipulation
var favoriteNumbers: Set<Int> = [3, 7, 10, 15]
favoriteNumbers.insert(20)
print("2. Updated set:", favoriteNumbers)

// 3. Dictionary Creation and Access
let programmingLanguages = [
    "Swift": 2014,
    "Python": 1991,
    "Java": 1995
]
print("3. Swift release year:", programmingLanguages["Swift"]!)

// 4. Array Element Update
var colors = ["Red", "Blue", "Green", "Yellow"]
colors[1] = "Black"
print("4. Updated colors:", colors)


print("\n=== Medium Tasks ===")

// 5. Set Intersection
let firstSet: Set<Int> = [1, 2, 3, 4]
let secondSet: Set<Int> = [3, 4, 5, 6]

let commonNumbers = firstSet.intersection(secondSet)
print("5. Intersection:", commonNumbers)

// 6. Dictionary Update
var studentScores = [
    "Alex": 80,
    "John": 75,
    "Emma": 90
]

studentScores.updateValue(95, forKey: "Emma")
print("6. Updated student scores:", studentScores)

// 7. Array Merge
let firstArray = ["apple", "banana"]
let secondArray = ["cherry", "date"]

let mergedArray = firstArray + secondArray
print("7. Merged array:", mergedArray)


print("\n=== Hard Tasks ===")

// 8. Dictionary Key Addition
var countries = [
    "Kazakhstan": 20000000,
    "USA": 340000000,
    "Japan": 124000000
]

countries["Germany"] = 84000000
print("8. Updated countries:", countries)

// 9. Set Union and Subtract
let animals1: Set<String> = ["cat", "dog"]
let animals2: Set<String> = ["dog", "mouse"]

let unionSet = animals1.union(animals2)
let finalSet = unionSet.subtracting(animals2)

print("9. Final set:", finalSet)

// 10. Nested Collection
let studentGrades = [
    "Alex": [85, 90, 78],
    "Emma": [92, 88, 95],
    "John": [75, 80, 82]
]

print("10. Emma's second grade:", studentGrades["Emma"]![1])