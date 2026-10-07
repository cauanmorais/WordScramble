//
//  ContentView.swift
//  WordScramble
//
//  Created by Cauan de Jesus Nascimento de Morais on 04/10/26.
//

import SwiftUI

struct ContentView: View {
    enum Status {
        case right
        case wrong
    }
    
    struct UsedWord: Identifiable {
        let id = UUID()
        let word: String
        let status: Status
        let itemScore: Int
    }
    
    // game related variables
    @State private var usedWords: [UsedWord] = []
    @State private var rootWord = ""
    @State private var newWord = ""
    
    @State private var score = 0
    private let maxTry = 3
    
    @State var showingEndGameAlert = false
    
    // error related variables
    @State private var errorMessage = ""
    @State private var errorTitle = ""
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Enter your word", text: $newWord)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section {
                    HStack {
                        Text("Used words")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(usedWords.count)/\(maxTry)")
                    }
                    
                    ForEach(usedWords) { item in
                        HStack {
                            Image(systemName: "\(item.word.count).circle")
                            Text(item.word)
                                .foregroundStyle((item.status == .right ? Color.blue : Color.red))
                            
                            Spacer()
                            
                            Text("\(item.status == .right ? "+" : "")\(item.itemScore)")
                                .foregroundStyle((item.status == .right ? Color.blue : Color.red))
                        }
                    }
                }
            }
            .navigationTitle(rootWord)
            .onSubmit(addNewWord)
            .onAppear(perform: startGame)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("New Game", systemImage: "arrow.counterclockwise", action: startGame)
                        .buttonStyle(.glass)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Text("Score: \(score)")
                        .font(.headline)
                        .monospacedDigit()
                }
            }
            .alert("Game finished", isPresented: $showingEndGameAlert) {
                Button("Restart game", action: startGame)
            } message: {
               Text("You finished with a score of \(score)")
            }
            .alert(errorTitle, isPresented: $showingError) { } message: {
                Text(errorMessage)
            }
        }
    }
    
    func addNewWord() {
        // lowercase and trim word, to make sure we don't add duplicate words with case difference
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard answer.count > 2 else {
            addWrongWord(answer)
            return wordError(title: "Invalid Word.", message: "Your typed word length should be more than two characters long")
        }
        
        guard answer != rootWord else {
            addWrongWord(answer)
            return wordError(title: "Invalid Word.", message: "The typed word is equal to the original word, please enter another one.")
        }
        
        guard isOriginal(word: answer) else {
            addWrongWord(answer)
                return wordError(title: "Duplicate word.", message: "You already typed this word, please enter another one.")
        }
        
        guard isPossible(word: answer) else {
            addWrongWord(answer)
            return wordError(title: "Wrong word.", message: "The typed word cannot be made using \(rootWord), please enter another one.")
        }
        
        guard isReal(word: answer) else {
            addWrongWord(answer)
            return wordError(title: "Invalid word.", message: "The typed word is not a real word, please enter another one.")
        }
        
        withAnimation {
            usedWords.insert(UsedWord(word: answer, status: .right, itemScore: 10), at: 0)
        }
        
        newWord = ""
        
        if usedWords.count == maxTry {
            endGame()
        }
    }
    
    func startGame() {
        // clean the used words for the new play
        usedWords.removeAll()
        
        // clean the game state
        score = 0
        
        // find the URL for start.txt in our app bundle
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: ".txt") {
            // load start.txt into a string
            if let startWords = try? String(contentsOf: startWordsURL, encoding: .ascii) {
                // split the string up into an array of strings, splitting on line breaks
                let allWords = startWords.components(separatedBy: "\n")
                
                // pick one random word, or use "starfire" as a sensible default.
                rootWord = allWords.randomElement() ?? "starfire"
                
                // if we are here, everything has worked, so we can exit
                return
            }
        }
        fatalError("Could not load start.txt from bundle")
    }
    
    func isOriginal(word: String) -> Bool {
        !usedWords.contains { $0.word == word }
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
        let mispelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        
        return mispelledRange.location == NSNotFound
    }
    
    func wordError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showingError = true
    }
    
    func endGame() {
        showingEndGameAlert = true
    }
    
    func addWrongWord(_ answer: String) {
        usedWords.insert(UsedWord(word: answer, status: .wrong, itemScore: -10), at: 0)
        
        newWord = ""
        
        if usedWords.count == maxTry {
            endGame()
        }
    }
}

#Preview {
    ContentView()
}
