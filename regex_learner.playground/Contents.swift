//
//  regex_learner.swift
//
//  Copyright © 2020 Bernardo Ferrari. All rights reserved.
//
//  This is an app to help user learn about Regular Expressions,
//  how they can be used and how useful they can be.
//  It contains 4 "screens" (variations of the same screen, but without navigation)
//  and progressively increases in difficulty.
//
//  Check my other projects: https://github.com/bernaferrari

import SwiftUI
import PlaygroundSupport

class ContentViewModel: ObservableObject {
    // the default values for each field on each screen
    let baseStrings = ["hmmm what's next for Apple? Next June!", "Hair Force One has landed", "Ber:1, Craig:2, Sylvester:3, Figma:4, Taylor:5, Dolores:6", ""]
    let regexStrings = ["(change this)", "(change this)", "(change this)", ""]
    let replaceWithStrings = ["", "(remove this)", "", ""]

    // go to the next or previous level. Updates the currentLevel which triggers [loadLevel] and refreshes the other variables.
    func updateLevel(updated_number: Int) {
        currentLevel = updated_number
    }

    // keeps track of the current level, goes from 0 to 3.
    @Published var currentLevel: Int = 0 {
        didSet {
            loadLevel()
        }
    }

    // on init, this must be called, else [baseString], [regexString] and [replaceWithString] won't have a value when app starts.
    init() {
        loadLevel()
    }

    func loadLevel() {
        baseString = baseStrings[currentLevel]
        regexString = regexStrings[currentLevel]
        replaceWithString = replaceWithStrings[currentLevel]
        showNextButton = false
    }

    @Published var baseString = "" {
        didSet {
            processDataChange()
        }
    }
    @Published var regexString = "" {
        didSet {
            processDataChange()
        }
    }
    @Published var replaceWithString = "" {
        didSet {
            processDataChange()
        }
    }

    // this won't have a didSet method because user shouldn't edit it..
    // even if is modified, it won't trigger [processDataChange]
    @Published var resultString = ""

    @Published var showNextButton = false

    // this is going to check if user input is correct, so that they can progress to next level
    func processDataChange() {
        if currentLevel == 0 {
            showNextButton = find(regex: regexString, base: baseString)
        } else if currentLevel == 1 {
            replaceAndGenerateResultString()
            // if "landed" or "Hair", "Force" and "One" have disappeared. The reason for not using "Hair Force One" is because this is a critical mission, and "air Force One" would be identified as a success, but you can clearly guess the H is missing.
            showNextButton = !find(regex: "landed", base: resultString) || (!find(regex: "Hair", base: resultString) && !find(regex: "Force", base: resultString) && !find(regex: "One", base: resultString))
        } else if currentLevel == 2 {
            replaceAndGenerateResultString()
            // this expression will only match when it finds 1,2,3,4,5...
            showNextButton = find(regex: "^(\\d+\\s*,{0,1}\\s*)*$", base: resultString)
        } else if currentLevel == 3 {
            // clear it up
            resultString = ""
        }
    }

    func replaceAndGenerateResultString() {
        resultString = baseString.replacingOccurrences(of: regexString, with: replaceWithString, options: [.regularExpression])
    }

    func find(regex: String, base: String) -> Bool {
        // only show nextButton when the array of matches is not empty
        return matches(for: regex, in: base).isEmpty == false
    }

  // copied from https://stackoverflow.com/a/27880748/4418073
  func matches(for regex: String, in text: String) -> [String] {

        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}

struct ContentView: View {

    @ObservedObject var viewModel = ContentViewModel()

    let missions = ["Your mission, should you choose to accept, is to create a regex that matches the base string. \n\nWhat!? Try tapping \"next\" into the \"regex expression\" field and await for further instructions.", "Your second mission is to redact. How do I remove something, you may ask? Well, you can replace it.. replace with nothing.\n\nNo one can know what Hair Force One is doing. To proceed, either write \"Hair Force One\" or \"landed\" in \"regex expression\" field. That way, it will remain a mystery.", "Houston, we have a problem! We are sharing too much personal data with our enginners. Your mission is to remove all names, only keep the numbers.\n\nThat seems hard. With one expression? Yep! Type \"\\w*:\" into the \"regex expression\" field and see the magic happen.\n\n \"\\w\" means any word (letter), \"*\" means from 0 occurences to infinity, and the \":\" because it is not considered a word."]

    let rewards = ["Congratulations! You created an expression without even knowing it. The button for next level was found!\n\nIf you paid attention, \"N\" was already a valid expression. Any letter or word (case sensitive) that matches a string is valid!", "Congrats! You have learned how to use an expression to find and replace information! This is heavily used in scripts, programming languages and text editors.\n\nRemember this next time you type Command+F.",
                   "Congrats! You just succeded into a more advanced use case.\n\nWhile, as you have just seen, it can be hard to read or understand what is going on, it can be extremely versatile and useful.", "Congratulations! You finished all the lessons!!\nYou helped Hair Force One, solved a privacy issue related to data mining and learned the basis of how these expressions work.\n\nThis page is a sandbox for you to play with it. Thanks for checking this app!!"]

// the name for each level
    let levels = ["Find", "Redact", "Multiple Replace", "Sandbox"]

    let lastLevel = 3

    var body: some View {

        VStack {
            // there is a HStack followed by VStack because that's the way I found to color the background
            // the background will be colored when user has completed the lesson, so they know (the keyboard might be on top of everything else)
            HStack {
                Spacer()
                VStack {
                Text("Regular Expressions")
                .font(.title)
                .fontWeight(.semibold)
                    .padding(.top, 8.0)

                Text("Level: \(viewModel.currentLevel) • \(levels[viewModel.currentLevel])")
                    .font(.caption)
            }.padding()
                Spacer()
            }
            .padding(0.0)
            .background(viewModel.showNextButton ? Color.green.opacity(0.20) : Color.clear)

            Form {
                Section(header: Text("base string")) {
                    // the base string can be modified, but it won't trigger update events, so the user can't cheat with it
                    // useful for clipboard, if user wants to copy the result.
                    TextField(
                        "Base string goes here. No need to cheat 😛",
                        text: $viewModel.baseString
                    )
                }

                Section(header: Text("regex expression")) {
                    // where the regex goes
                    TextField(
                        "Insert the expression here",
                        text: $viewModel.regexString
                    )
                }

                if viewModel.currentLevel > 0 {
                    // where string to be replaced goes. Not going to be used at first screen,
                    // so the app can progress in difficulty and user can get familiar to the interface
                    Section(header: Text("replace with")) {
                        TextField(
                            "Insert the replacement here",
                            text: $viewModel.replaceWithString
                        )
                    }

                    // the result after the string is replaced. Can also be modified by user,
                    // because of copy/paste support and to keep layout easier.
                    // if anyone modifies it, the person is cheating.
                    Section(header: Text("result")) {
                        TextField(
                            "Result goes here",
                            text: $viewModel.resultString
                        )
                    }
                }

                // only shows the next button after mission has been accomplished
                if viewModel.showNextButton {
                    Section {
                        Button(action: {
                              self.viewModel.updateLevel(updated_number: self.viewModel.currentLevel + 1)
                          }) {
                              Text("Next")
                              .fontWeight(.semibold)
                              .cornerRadius(40)
                          }

                          Text(rewards[viewModel.currentLevel])
                          .padding()
                          .background(Color.green.opacity(0.15))
                    }
                }

                // when someone finishes the game, they deserve a different card
                if viewModel.currentLevel == lastLevel {
                    Text(rewards[viewModel.currentLevel])
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                    .padding()
                        .background(Color.orange.opacity(0.25))
                } else if viewModel.currentLevel < lastLevel {
                    // there is no mission at the last level, so ignore it
                    Section {
                        Text(missions[viewModel.currentLevel])
                        .padding()
                        .background(Color.blue.opacity(0.15))
                    }
                }

                // there is no back button at the first level, so ignore it
                if viewModel.currentLevel > 0 {
                    Section {

                      Button(action: {
                        self.viewModel.updateLevel(updated_number: self.viewModel.currentLevel - 1)
                      }) {
                          Text("Previous")
                          .fontWeight(.semibold)
                          .cornerRadius(40)
                      }
                  }
                }
            }
        }
    }
}

// Level 1:
// Find the "Next" button

// Level 2:
// Redact important stuff

// Level 3:
// Replace multiple fields of personal data

// Level 4:
// Sandbox

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

PlaygroundPage.current.setLiveView(ContentView())
