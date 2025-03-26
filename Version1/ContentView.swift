//
//  WordFind
//  Steve Groves Jan 2025
//

import SwiftUI

struct Title: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title3)
            .cornerRadius(25)
            .buttonStyle(.bordered)
    }
}

extension View {
    func buttonStyleModifier() -> some View
    {
        modifier(Title())
    }
}

struct ContentView: View {
    @AppStorage("highScoreL") var highScoreL: Int = 0
    @AppStorage("highScoreM") var highScoreM: Int = 0
    @AppStorage("highScoreH") var highScoreH: Int = 0

    @State private var usedWords = [String]()
    @State private var rootWord = ""
    @State private var newWord = ""
    @State private var score = 0
    @State private var wordCount = 3
    @State private var showLevel = true
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    
    @FocusState private var keepFocus: Bool
    
    let skillColour: [Color] = [.green, .yellow, .red]
    let skillTitle = ["Easy", "Medium", "Hard"]
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Current high score: \(chooseScore())")
                    .font(.title3)
                    .frame(maxWidth: .infinity, maxHeight: 30)
                    .background(skillColour[wordCount-3].opacity(0.40))
                List {
                    Section {
                        HStack {
                            Text("WordFinder:")
                                .foregroundStyle(Color.accentColor)
                            Spacer()
                            Text("\(rootWord)")
                                .foregroundStyle(Color.accentColor)
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    Section {
                        TextField("Type word here", text: $newWord)
                            .focused($keepFocus, equals: true)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .onSubmit {
                                keepFocus = keepFocus
                                addNewWord()
                            }
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
                        Button("New Word") {
                            SaveHighScore()
                        }
                        .buttonStyleModifier()
                        Spacer()
                        Spacer(minLength: 30)
                        Text("Score \(usedWords.count)")
                            .font(.title2)
                    },
                trailing:
                    Button("Skill Level") {
                        changeSkill()
                    }
                    .buttonStyleModifier()
                    .foregroundStyle(showLevel ? Color.accentColor : .gray)
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
                rootWord = allWords.randomElement() ?? "silkworm"
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
    }
    
    func SaveHighScore() {
        score = usedWords.count
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
}

#Preview {
    ContentView()
}
