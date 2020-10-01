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

var manager = RegistryManager()
let appname = "morphictest"

if CommandLine.argc > 2 //run single automated command, do not begin interactive client
{
    if manager.load(registry: CommandLine.arguments[1])
    {
        switch CommandLine.arguments[2]
        {
        case "list":
            switch CommandLine.argc
            {
            case 3:
                manager.list()
            case 4:
                manager.listSpecific(solution: CommandLine.arguments[3])
            default:
                print("[ERROR]: Incorrect number of parameters. Use: \(appname) <filename> list [solution]")
            }
        case "listsolutions":
            manager.listSolutions()
        case "info":
            if(CommandLine.argc == 5)
            {
                manager.info(solution: CommandLine.arguments[3], preference: CommandLine.arguments[4])
            }
            else
            {
                print("[ERROR]: Incorrect number of parameters. Use: \(appname) <filename> info <solution> <preference>")
            }
        case "get":
            switch CommandLine.argc
            {
            case 3:
                manager.get()
            case 4:
                manager.get(solution: CommandLine.arguments[3])
            case 5:
                manager.get(solution: CommandLine.arguments[3], preference: CommandLine.arguments[4])
            default:
                print("[ERROR]: Incorrect number of parameters. Use: \(appname) <filename> get [solution] [preference]")
            }
        case "set":
            if(CommandLine.argc == 6)
            {
                manager.set(solution: CommandLine.arguments[3], preference: CommandLine.arguments[4], value: CommandLine.arguments[5])
            }
            else
            {
                print("[ERROR]: Incorrect number of parameters. Use: \(appname) <filename> set <solution> <preference> <value>")
            }
        case "help":
            helpdoc(cmdline: true)
        default:
            print("[ERROR]: Unrecognized command. Commands: list, listsolutions, info, get, set, help")
        }
    }
    else
    {
        print("[ERROR]: Could not load file \(CommandLine.arguments[1]) as a valid solutions registry JSON file. Check filename and try again.")
    }
}
else if(CommandLine.argc == 2)
{
    if manager.load(registry: CommandLine.arguments[1])
    {
        print("Morphic Manual Solutions Registry Tester")
        print("Copyright 2020 Raising the Floor - International")
        print()
        print("Solutions file loaded successfully.")
        print()
        var loop = true
        while(loop)
        {
            print("Please enter a command, type 'help' to list all commands:")
            print("> ", terminator:"")
            let line = readLine()
            let args = line?.components(separatedBy: " ") ?? []
            if(args.count > 0)
            {
                switch args[0] {
                case "list":
                    switch args.count
                    {
                    case 1:
                        manager.list()
                    case 2:
                        manager.listSpecific(solution: args[1])
                    default:
                        print("[ERROR]: Incorrect number of parameters. Use: list [solution]")
                    }
                case "listsolutions":
                    manager.listSolutions()
                case "info":
                    if(args.count == 3)
                    {
                        manager.info(solution: args[1], preference: args[2])
                    }
                    else
                    {
                        print("[ERROR]: Incorrect number of parameters. Use: info <solution> <preference>")
                    }
                case "get":
                    switch args.count
                    {
                    case 1:
                        manager.get()
                    case 2:
                        manager.get(solution: args[1])
                    case 3:
                        manager.get(solution: args[1], preference: args[2])
                    default:
                        print("[ERROR]: Incorrect number of parameters. Use: get [solution] [preference]")
                    }
                case "set":
                    if(args.count != 4)
                    {
                        print("[ERROR]: Incorrect number of parameters. Use: set <solution> <preference> <value>")
                    }
                    else
                    {
                        manager.set(solution: args[1], preference: args[2], value: args[3])
                    }
                case "help":
                    helpdoc(cmdline: false)
                case "quit":
                    loop = false
                case "exit":
                    loop = false
                default:
                    print("[ERROR]: Invalid command")
                }
            }
        }
    }
    else if CommandLine.arguments[1] == "help"
    {
        helpdoc(cmdline: true)
    }
    else
    {
        print("[ERROR]: Could not load file \(CommandLine.arguments[1]) as a valid solutions registry JSON file. Check filename and try again.")
    }
}
else
{
    print("[ERROR]: Valid solutions registry file path required. Use: \(appname) <filename>")
}

func helpdoc(cmdline: Bool)
{
    var header = ""
    if cmdline
    {
        header = "\(appname) <filename> "
        print("Morphic Manual Solutions Registry Tester")
        print("Copyright 2020 Raising the Floor - International")
        print()
    }
    print("\t\(header)listsolutions")
    print("Lists all solutions without their settings for quick lookup")
    print()
    print("\t\(header)list")
    print("\t\(header)list <solution>")
    print("Lists all solutions and settings from the registry, or if provided a solution, only lists settings for that solution")
    print()
    print("\t\(header)info <solution> <preference>")
    print("Gives you verbose info on a particular setting in the registry")
    print()
    print("\t\(header)get")
    print("\t\(header)get <solution>")
    print("\t\(header)get <solution> <preference>")
    print("Displays the current value of a setting, all settings in a solution, or all settings in the registry depending on provided parameters")
    print()
    print("\t\(header)set <solution> <preference> <value>")
    print("Changes the value of a setting, if possible")
    print()
    if cmdline
    {
        return
    }
    print("\texit")
    print("Ends the program")
    print()
}
