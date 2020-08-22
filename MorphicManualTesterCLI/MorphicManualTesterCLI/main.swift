// Copyright 2020 Raising the Floor - International
//
// Licensed under the New BSD license. You may not use this file except in
// compliance with this License.
//
// You may obtain a copy of the License at
// https://github.com/GPII/universal/blob/master/LICENSE.txt
//
// The R&D leading to these results received funding from the:
// * Rehabilitation Services Administration, US Dept. of Education under
//   grant H421A150006 (APCP)
// * National Institute on Disability, Independent Living, and
//   Rehabilitation Research (NIDILRR)
// * Administration for Independent Living & Dept. of Education under grants
//   H133E080022 (RERC-IT) and H133E130028/90RE5003-01-00 (UIITA-RERC)
// * European Union's Seventh Framework Programme (FP7/2007-2013) grant
//   agreement nos. 289016 (Cloud4all) and 610510 (Prosperity4All)
// * William and Flora Hewlett Foundation
// * Ontario Ministry of Research and Innovation
// * Canadian Foundation for Innovation
// * Adobe Foundation
// * Consumer Electronics Association Foundation

import Foundation
import Darwin

var manager = RegistryManager()
let appname = "morphictest"

if CommandLine.argc > 2 //run single automated command, do not begin interactive client
{
    if manager.load(registry: CommandLine.arguments[1])
    {
        switch CommandLine.arguments[2] {
        case "list":
            if(CommandLine.argc == 3)
            {
                manager.list()
            }
            else if(CommandLine.argc == 4)
            {
                manager.listSpecific(solution: CommandLine.arguments[3])
            }
            else
            {
                print("[ERROR]: Incorrect number of parameters. Use: \(appname) <filename> list [solution]")
            }
            break
        case "listsol":
            manager.listSolutions()
            break
        case "info":
            if(CommandLine.argc == 5)
            {
                manager.info(solution: CommandLine.arguments[3], preference: CommandLine.arguments[4])
            }
            else
            {
                print("[ERROR]: Incorrect number of parameters. Use: \(appname) <filename> info <solution> <preference>")
            }
            break
        case "read":
            if(CommandLine.argc == 3)
            {
                manager.get()
            }
            else if(CommandLine.argc == 4)
            {
                manager.get(solution: CommandLine.arguments[3])
            }
            else if(CommandLine.argc == 5)
            {
                manager.get(solution: CommandLine.arguments[3], preference: CommandLine.arguments[4])
            }
            else
            {
                print("[ERROR]: Incorrect number of parameters. Use: \(appname) <filename> get [solution] [preference]")
            }
            break
        case "write":
            if(CommandLine.argc == 6)
            {
                manager.set(solution: CommandLine.arguments[3], preference: CommandLine.arguments[4], value: CommandLine.arguments[5])
            }
            else
            {
                print("[ERROR]: Incorrect number of parameters. Use: \(appname) <filename> set <solution> <preference> <value>")
            }
            break
            case "help":
                print("\(appname) <filename> list [solution]:")
                print("\tLists all solutions and settings from the registry, or if provided a solution, only lists settings for that solution")
                print("\(appname) <filename> listsol")
                print("\tLists all solutions without their settings for quick lookup")
                print()
                print("\(appname) <filename> info <solution> <preference>:")
                print("\tGives you verbose info on a particular setting in the registry")
                print()
                print("\(appname) <filename> read [solution] [preference]:")
                print("\tLists the current value of a setting, all settings in a solution, or all settings in the registry depending on provided parameters")
                print()
                print("\(appname) <filename> write <solution> <preference> <value>:")
                print("\tChanges the value of a setting, if possible")
                print()
                break
        default:
            print("[ERROR]: Unrecognized command. Commands: list, listsol, info, get, set, help")
        }
    }
}
else
{
    var loaded = false
    if CommandLine.argc == 2
    {
        if !manager.load(registry: CommandLine.arguments[1])
        {
            print("[ERROR]: Could not load file \(CommandLine.arguments[1]) as a valid solutions registry JSON file. Check filename and try again.")
        }
    }
    else
    {
        print("[ERROR]: Valid solutions registry file path required. Use: \(appname) <filename>")
        exit(0)
    }
    while(!loaded)
    {
        print("Please provide the file path to a valid solutions registry JSON file: ")
        print("> ", terminator:"")
        let address : String = readLine() ?? ""
        if(address == "quit" || address == "exit")
        {
            exit(0)
        }
        loaded = manager.load(registry: address)
    }
    print("Solutions file loaded successfully.")
    print("Welcome to the Morphic Manual Solutions Registry Tester.")
    print("Morphic is Copyright 2020 Raising the Floor - International")
    print()
    while(true)
    {
        print("Please enter a command, type 'help' to list all commands:")
        print("> ", terminator:"")
        let line = readLine()
        let args = line?.components(separatedBy: " ") ?? []
        if(args.count > 0)
        {
            switch args[0] {
            case "list":
                if(args.count == 1)
                {
                    manager.list()
                }
                else if(args.count == 2)
                {
                    manager.listSpecific(solution: args[1])
                }
                else
                {
                    print("[ERROR]: Incorrect number of parameters. Use: list [solution]")
                }
                break
            case "listsol":
                manager.listSolutions()
                break
            case "info":
                if(args.count == 3)
                {
                    manager.info(solution: args[1], preference: args[2])
                }
                else
                {
                    print("[ERROR]: Incorrect number of parameters. Use: info <solution> <preference>")
                }
                break
            case "read":
                if(args.count == 1)
                {
                    manager.get()
                }
                else if(args.count == 2)
                {
                    manager.get(solution: args[1])
                }
                else if(args.count == 3)
                {
                    manager.get(solution: args[1], preference: args[2])
                }
                else
                {
                    print("[ERROR]: Incorrect number of parameters. Use: get [solution] [preference]")
                }
                break
            case "write":
                if(args.count != 4)
                {
                    print("[ERROR]: Incorrect number of parameters. Use: set <solution> <preference> <value>")
                }
                else
                {
                    manager.set(solution: args[1], preference: args[2], value: args[3])
                }
                break
            case "help":
                print("list [solution]:")
                print("\tLists all solutions and settings from the registry, or if provided a solution, only lists settings for that solution")
                print("listsol")
                print("\tLists all solutions without their settings for quick lookup")
                print()
                print("info <solution> <preference>:")
                print("\tGives you verbose info on a particular setting in the registry")
                print()
                print("read [solution] [preference]:")
                print("\tLists the current value of a setting, all settings in a solution, or all settings in the registry depending on provided parameters")
                print()
                print("write <solution> <preference> <value>:")
                print("\tChanges the value of a setting, if possible")
                print()
                print("exit:")
                print("\tEnds the program")
                print()
                break
            case "quit":
                exit(0)
                break
            case "exit":
                exit(0)
                break
            default:
                print("[ERROR]: Invalid command")
            }
        }
    }
}
