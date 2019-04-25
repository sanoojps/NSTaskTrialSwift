//
//  main.swift
//  NSTaskTrial
//
//  Created by carvak on 24/04/2019.
//  Copyright © 2019 sanooj. All rights reserved.
//

import Foundation

print("Hello, World!")

/// get command line argumenets if passed in

for argv in CommandLine.arguments
{
    print(argv)
}

func run_zip_blocking()
{
    // command
    let task = Process()
    task.launchPath =
    "/usr/bin/zipinfo"
    
    // parameters
    var argumnets: [String] = []
    argumnets.append("-1")
    let filePath =
    "/Users/carvak/Downloads/sample.zip"
    // CommandLine.arguments.first!
    argumnets.append(filePath)
    
    task.arguments =
    argumnets
    
    // create a pipe
    let outPipe = Pipe()
    task.standardOutput = outPipe
    
    // start
    task.launch()
    
    // Read the output
    let fileHandle =
        outPipe.fileHandleForReading
    
    // read
    let data: Data =
        fileHandle.readDataToEndOfFile()
    
    // wait for task to finish
    task.waitUntilExit()
    
    // status
    let status: Int32 =
        task.terminationStatus
    
    if status != 0 {
        // error
        print("status")
        print(status)
    } else {
        let outputString =
            String.init(data: data, encoding: String.Encoding.utf8)
        
        // break output into new lines
        let filenames =
            outputString?.components(separatedBy: CharacterSet.newlines)
        
        print(filenames!)
    }
    
}


run_zip_blocking()

class AsyncPing {
    
    var data: Data =
        Data()
    
    var _shouldRun: Bool =
    true
    
    var shouldRun: Bool {
        get {
            return self._shouldRun
        }
        set {
            objc_sync_enter(self)
            self._shouldRun =
            newValue
            objc_sync_exit(self)
            
            if newValue == false
            {
                // remove observers
                NotificationCenter.default.removeObserver(
                    self,
                    name: FileHandle.readCompletionNotification,
                    object: nil
                )
                NotificationCenter.default.removeObserver(
                    self,
                    name: Process.didTerminateNotification,
                    object: nil
                )
                
                CFRunLoopStop(CFRunLoopGetCurrent())
            }
        }
    }
    
    func run_ping_async()
    {
        // ping -c10 4.2.2.2
        let task =
            Process()
        
        let commandLocale =
        "/sbin"
        
        let commandName =
        "ping"
        
        let launchPath =
            commandLocale + "/" + commandName
        
        task.launchPath =
        launchPath
        
        var arguments: [String] =
            []
        
        arguments.append("-c10")
        arguments.append("4.2.2.2")
        
        task.arguments =
        arguments
        
        // create a new pipe for standardOutput
        let pipe =
            Pipe()
        
        task.standardOutput =
        pipe
        
        // get the file handle
        let fileHandle: FileHandle =
            pipe.fileHandleForReading
        
        // notifications
        let notificationCenter =
            NotificationCenter.default
        
        //readCompletionNotification
        notificationCenter.addObserver(
            self,
            selector: #selector(fileReadCompletionHandler(_:)),
            name: FileHandle.readCompletionNotification,
            object: fileHandle
        )
        
        // task termination
        notificationCenter.addObserver(
            self,
            selector: #selector(taskCompletionHandler(_:)),
            name: Process.didTerminateNotification,
            object: task
        )
        
        // launch task
        task.launch()
        
        Thread.detachNewThread {
            // notify
            fileHandle.readInBackgroundAndNotify()
            
            // wait on the thread
            while self.shouldRun {
                CFRunLoopRun()
            }
        }
        
        // park the main thread
        while self.shouldRun {
            CFRunLoopRun()
        }
    }
    
    @objc
    func fileReadCompletionHandler(_ notification: NSNotification) -> Void
    {
        //print(notification.name)
        
        // extract data
        guard let outputData: Data =
            notification.userInfo?[NSFileHandleNotificationDataItem] as? Data else
        {
            print("no data")
            return
        }
        
        let consoleOutPut: String? =
            String.init(
                data: outputData,
                encoding: String.Encoding.utf8
                )?.trimmingCharacters(in: CharacterSet.newlines)
        
        print(consoleOutPut ?? "")
        //self.data.append(outputData)
        
        // if task hasn't terminated
        // read again
        let fileHandle =
            notification.object as? FileHandle
        
        fileHandle?.readInBackgroundAndNotify()
    }
    
    @objc
    func taskCompletionHandler(_ notification: NSNotification) -> Void
    {
        //print(notification.name)
        //        let consoleOutPut: String? =
        //            String.init(
        //                data: self.data,
        //                encoding: String.Encoding.utf8
        //        )
        //        print(consoleOutPut ?? "")
        
        self.shouldRun =
        false
    }
    
}


AsyncPing().run_ping_async()
