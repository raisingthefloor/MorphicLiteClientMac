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
        switch CommandLine.arguments[2] {
        case "list":
            manager.list()
            break
        case "info":
            if(CommandLine.argc != 5)
            {
                print("[ERROR]: Incorrect number of parameters. Use: \(appname) [filename] info [solution] [setting]")
            }
            else
            {
                manager.info(solution: CommandLine.arguments[3], preference: CommandLine.arguments[4])
            }
            break
        case "read":
            if(CommandLine.argc != 5)
            {
                print("[ERROR]: Incorrect number of parameters. Use: \(appname) [filename] read [solution] [setting]")
            }
            else
            {
                manager.read(solution: CommandLine.arguments[3], preference: CommandLine.arguments[4])
            }
            break
        case "write":
            if(CommandLine.argc != 6)
            {
                print("[ERROR]: Incorrect number of parameters. Use: \(appname) [filename] write [solution] [setting] [value]")
            }
            else
            {
                manager.write(solution: CommandLine.arguments[3], preference: CommandLine.arguments[4], value: CommandLine.arguments[5])
            }
            break
        default:
            print("[ERROR]: Unrecognized command. Command list: list, info, read, write")
        }
    }
}
else
{
    var loaded = false
    if CommandLine.argc == 2
    {
        loaded = manager.load(registry: CommandLine.arguments[1])
    }
    else
    {
        print("Please input a valid solutions registry JSON file")
    }
    while(!loaded)
    {
        let address : String = readLine() ?? ""
        loaded = manager.load(registry: address)
    }
    print("Solutions file loaded successfully.")
    var loop = true
    while(loop)
    {
        print("Please enter a command, type 'help' to list all commands:")
        let line = readLine()
        let args = line?.components(separatedBy: " ") ?? []
        if(args.count > 0)
        {
            switch args[0] {
            case "list":
                manager.list()
                break
            case "info":
                if(args.count != 3)
                {
                    print("[ERROR]: Incorrect number of parameters. Use: info [solution] [setting]")
                }
                else
                {
                    manager.info(solution: args[1], preference: args[2])
                }
                break
            case "read":
                if(args.count != 3)
                {
                    print("[ERROR]: Incorrect number of parameters. Use: read [solution] [setting]")
                }
                else
                {
                    manager.read(solution: args[1], preference: args[2])
                }
                break
            case "write":
                if(args.count != 4)
                {
                    print("[ERROR]: Incorrect number of parameters. Use: write [solution] [setting] [value]")
                }
                else
                {
                    manager.write(solution: args[1], preference: args[2], value: args[3])
                }
                break
            case "help":
                print("list:")
                print("\tLists all solutions and settings")
                print("info [solution] [setting]:")
                print("\tGives you info on a particular setting (for now just data type)")
                print("read [solution] [setting]:")
                print("\tLists the current value of a setting")
                print("write [solution] [setting] [value]:")
                print("\tChanges the value of a setting, if possible")
                print("quit:")
                print("\tEnds the program")
                break
            case "quit":
                loop = false
                break
            default:
                print("[ERROR]: Invalid command")
            }
        }
    }
}
