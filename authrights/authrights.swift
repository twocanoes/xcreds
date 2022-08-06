//
//  main.swift
//  authrights
//
//  Created by Timothy Perfitt on 7/11/22.
//

import ArgumentParser

@main
struct AuthRights: ParsableCommand {

    @Flag(name: .shortAndLong, help: "print rights")
    var printRights:Int

    @Flag(name: .shortAndLong, help: "delete right")
    var deleteRight:Int

    @Option(name: .shortAndLong, help: "insert before this rule")
    var beforeThisRight: String?

    @Option(name: .shortAndLong, help: "insert after this rule")
    var afterThisRight: String?

    @Option(name: .shortAndLong, help: "replace this rule")
    var replaceThisRight: String?

    @Argument(help: "Rule to insert")
    var right: String?

    mutating func run() throws {

       let manager = AuthorizationDBManager.shared
        if (printRights == 1) {
            let info = manager.consoleRights().joined(separator: "\n")

            print(info)
            return
        }

        guard let right = right else {
            print("must specify right")
            return
        }

        if deleteRight == 1 {
            if manager.remove(right: right)==false {
//                print("error removing right")
            }

        }
        else if beforeThisRight != nil {

            if manager.insertRight(newRight:right , beforeRight: beforeThisRight!)==false{

                print("error inserting before right")
            }
        }
        else if afterThisRight != nil {
//            print("inserting right after")
            if manager.insertRight(newRight: right, afterRight: afterThisRight!)==false{

                print("error inserting after right")
            }

        }
        else if replaceThisRight != nil {
            if manager.replace(right: replaceThisRight!, withNewRight: right)==false{

                print("error replacing right")
            }

        }
        else {
            print("No placement option specified")
        }
    }
}
