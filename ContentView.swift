//
//  ContentView.swift
//
//  WordFind
//  Steve Groves Jan 2025
//

import SwiftUI

struct ContentView: View {
    @AppStorage("highScoreL") var highScoreL: Int = 0
    @AppStorage("highScoreM") var highScoreM: Int = 0
    @AppStorage("highScoreH") var highScoreH: Int = 0
    
    var valueCount: Int {
        var totalScore = 0
        for value in 0..<usedWords.count {
            totalScore += usedWords[value].count
        }
        return totalScore
    }
    
    var mostUsed: [Int] {
        var rankedScore = [Int]()
        for countUsedLetters in 3..<9 {
            let countUsed = usedWords.count(where: { $0.count == countUsedLetters })
            rankedScore.append(countUsedLetters)
            rankedScore.append(countUsed)
        }
        return rankedScore
    }
    
    @State private var usedWords = [String]()
    @State private var rootWord = ""
    @State private var newWord = ""
    @State private var score = 0
    @State private var wordCount = 3
    @State private var showLevel = true
    @State private var startTimer = false
   
    @State private var gameTimer = 120
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @FocusState private var keepFocus: Bool
    
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    
    let skillColour: [Color] = [.green, .yellow, .red]
    let skillTitle = ["Easy", "Medium", "Hard"]
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("High score: \(chooseScore())")
                    Spacer()
                    Text("Timer: \(gameTimer)")
                    Spacer()
                    Text("Score: \(usedWords.count)")
                    Spacer()
                }
                .font(.title3)
                .frame(maxWidth: .infinity, maxHeight: 40, alignment: .leading)
                .padding(.horizontal)
                .background(Color(skillColour[wordCount-3].opacity(0.4)))
                .onReceive(timer) { time in
                    guard startTimer else { return }
                    if gameTimer  > 0 {
                        gameTimer  -= 1
                    } else {
                        startTimer = false
                        rootWord = ""
                        wordError(title: "Game Over", message: "You found \(usedWords.count) words and scored \(valueCount)")
                        SaveHighScore()
                    }
                }
                Divider()
                List {
                    Section {
                        HStack {
                            Text("WordFinder:")
                                .foregroundStyle(Color.accentColor)
                            Spacer()
                            Text("\(rootWord)")
                                .textCase(.uppercase)
                                .foregroundStyle(Color.accentColor)
                                .font(.title2)
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    
                    Section {
                        TextField("Type word here", text: $newWord)
                            .focused($keepFocus, equals: true)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .onSubmit(validateTimer)
                    }
                    Section {
                        ForEach(usedWords, id: \.self) { word in
                            HStack {
                                Image(systemName: "\(word.count).circle")
                                Divider()
                                Text(word)
                                    .fontDesign(.rounded)
                                    .font(.title2)
                            }
                        }
                    }
                }
                HStack {
                    Text("Skill level = \(skillTitle[wordCount-3])")
                    Image(systemName: "\(wordCount).circle")
                    Text("letters")
                }
                .frame(maxWidth: .infinity, maxHeight: 30)
                .background(Color(skillColour[wordCount-3].opacity(0.4)))
            }
            .navigationBarItems(
                leading:
                    HStack {
                        Button("Next Word") {
                            startTimer = true
                            SaveHighScore()
                        }
                        .font(.title3)
                        .cornerRadius(25)
                        .buttonStyle(.bordered)
                    },
                trailing:
                    Button("Skill Level") {
                        changeSkill()
                    }
                    .font(.title3)
                    .foregroundStyle(showLevel ? Color.accentColor : .gray)
                    .cornerRadius(25)
                    .buttonStyle(.bordered)
            )
            .font(.title2)
            .onAppear(perform: startGame)
            .alert(errorTitle, isPresented: $showingError) { } message: {
                Text(errorMessage)
            }
        }
    }
    
    func addNewWord() {
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
       
        guard answer.count > 0 else { return }
        
        guard isOriginal(word: answer) else {
            wordError(title: "Word used already", message: "Be more original!")
            newWord = ""
            return
        }
        
        guard isPossible(word: answer) else {
            wordError(title: "Word not possible", message: "You can't spell that word from '\(rootWord)'!")
            newWord = ""
            return
        }
        
        guard isReal(word: answer) else {
            wordError(title: "Word not recognized", message: "You can't just make them up, you know!")
            newWord = ""
            return
        }
        
        guard isGreaterThanwordCount(word: answer) else {
            wordError(title: "Word too short", message: "You can't use words less than \(wordCount) letters")
            newWord = ""
            return
        }
        
        withAnimation {
            usedWords.insert(answer, at: 0)
            showLevel = false
        }
        
        newWord = ""
    }
    
    func startGame() {
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordsURL) {
                let allWords = startWords.components(separatedBy: "\n")
                if startTimer == true {
                    rootWord = allWords.randomElement() ?? "silkworm"
                }
                return
            }
        }
        
        fatalError("Could not load start.txt from bundle.")
    }
    
    func isOriginal(word: String) -> Bool {
        !usedWords.contains(word)
    }
    
    func isPossible(word: String) -> Bool {
        var tempWord = rootWord
        
        for letter in word {
            if let pos = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: pos)
            } else {
                return false
            }
        }
        return true
    }
    
    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        return misspelledRange.location == NSNotFound
    }
    
    func isGreaterThanwordCount(word: String) -> Bool {
        if word.count >= wordCount {
            return true
        }
        return false
    }
    
    func timerStopped() -> Bool {
        if startTimer {
            return true
        }
        return false
    }
    
    func wordError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showingError = true
    }
    
    func resetGame() {
        startGame()
        usedWords = [String]()
        newWord = ""
        showLevel = true
        gameTimer  = 120
    }
    
    func SaveHighScore() {
        score = valueCount
        switch wordCount {
        case 3:
            if highScoreL < score {
                highScoreL = score
            }
        case 4:
            if highScoreM < score {
                highScoreM = score
            }
        case 5:
            if highScoreH < score {
                highScoreH = score
            }
        default:
            score = 0
        }
        resetGame()
    }
    
    func changeSkill() {
        if showLevel == true {
            wordCount += 1
            if wordCount > 5 {
                wordCount = 3
            }
        }
    }
    
    func chooseScore() -> Int {
        switch wordCount {
        case 3:
            return highScoreL
        case 4:
            return highScoreM
        case 5:
            return highScoreH
        default:
            return 0
        }
    }
    
    func validateTimer() {
        guard gameTimer > 0 && startTimer else { return }
        keepFocus = keepFocus
        addNewWord()
    }
}

#Preview {
    ContentView()
}
