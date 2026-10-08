
 // Assignment #1: Your Life Story in Swift
 // iOS Mobile Development

 // Step 1: Personal Information
 var firstName: String = "Yerassyl"
 var lastName: String = "Karas"
 var age: Int = 20
 var birthYear: Int = 2006
 var isStudent: Bool = true
 var height: Double = 1.73

 // Bonus Challenge: Calculate age from the birth year
 let currentYear: Int = 2026
 let calculatedAge: Int = currentYear - birthYear

 // Step 2: Hobbies and Interests
 var hobby: String = "watching movies"
 var numberOfHobbies: Int = 4
 var favoriteNumber: Int = 7
 var isHobbyCreative: Bool = false
 var otherInterest: String = "music"

 // Bonus Task: Future goals and emoji variables
 var futureGoals: String = "find a job"
 let 🎬: String = "🎬"
 let 🎵: String = "🎵"
 let 🎯: String = "🎯"

 // Convert Bool values into natural English sentences
 let studentStatus: String = isStudent
     ? "I am currently a student"
     : "I am not currently a student"

 let hobbyDescription: String = isHobbyCreative
     ? "I think it is a creative hobby."
     : "I do not think it is a creative hobby."

 // Step 3: Create a Summary of My Life Story
 let lifeStory: String = """
 My name is \(firstName) \(lastName). I am \(age) years old, and I was born in \(birthYear).
 My height is \(height) meters. \(studentStatus).
 \(🎬) My favorite hobby is \(hobby). \(hobbyDescription)
 I have \(numberOfHobbies) hobbies in total, and my favorite number is \(favoriteNumber).
 \(🎵) I also enjoy \(otherInterest).
 \(🎯) In the future, I want to \(futureGoals).
 My calculated age for \(currentYear) is \(calculatedAge).
 """

 // Step 4: Print My Life Story
 print(lifeStory)
