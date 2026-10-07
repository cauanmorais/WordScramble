//
//  ContentView.swift
//  WordScramble
//
//  Created by Cauan de Jesus Nascimento de Morais on 04/10/26.
//

import SwiftUI

struct ContentView: View {
    // game related variables
    @State private var usedWords: [String] = []
    @State private var rootWord = ""
    @State private var newWord = ""
    
    @State private var score = 0
    @State private var matches = 0
    private let maxTry = 10
    
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
                    
                    ForEach(usedWords, id: \.self) { word in
                        HStack {
                            Image(systemName: "\(word.count).circle")
                            Text(word)
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
            .alert(errorTitle, isPresented: $showingError) { } message: {
                Text(errorMessage)
            }
        }
    }
    
    func addNewWord() {
        // lowercase and trim word, to make sure we don't add duplicate words with case difference
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // exit if the remaining string is less than three character or the remaining string is equal to the root word
        guard answer.count > 3 else {
            return wordError(title: "Invalid Word.", message: "Your typed word length should be more than three characters long")
        }
        
        guard answer != rootWord else {
            return wordError(title: "Invalid Word.", message: "The typed word is equal to the original word, please enter another one.")
        }
        
        
        guard isOriginal(word: answer) else {
                return wordError(title: "Duplicate word.", message: "You already typed this word, please enter another one.")
        }
        
        guard isPossible(word: answer) else {
            return wordError(title: "Wrong word.", message: "The typed word cannot be made using \(rootWord), please enter another one.")
        }
        
        guard isReal(word: answer) else {
            return wordError(title: "Invalid word.", message: "The typed word is not a real word, please enter another one.")
        }
        
        withAnimation {
            usedWords.insert(answer, at: 0)
        }
        newWord = ""
    }
    
    func startGame() {
        // clean the used words for the new play
        usedWords.removeAll()
        
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
        let mispelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        
        return mispelledRange.location == NSNotFound
    }
    
    func wordError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showingError = true
    }
}

#Preview {
    ContentView()
}
