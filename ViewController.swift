//
//  ViewController.swift
//  HackIRC
//
//  Created by Joel Blumenthal on 2/2/16.
//  Copyright © 2016 Joel Blumenthal. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    //storyboard variables
    @IBOutlet weak var serverField: NSTextField!
    @IBOutlet weak var loginButton: NSButton!
    @IBOutlet weak var logOutButton: NSButton!
    @IBOutlet weak var chatHandleField: NSTextField!
    @IBOutlet weak var chatField: NSScrollView!
    @IBOutlet var chatFieldText: NSTextView!
    @IBOutlet weak var sendField: NSTextField!
    @IBOutlet weak var sendButton: NSButton!
    @IBOutlet weak var loggedInLabel: NSTextField!
    
    //socket variables
    var addr = ""
    let port = 7777
    var inp: NSInputStream?
    var out: NSOutputStream?
    
    //timer, lastUpdated, textLog, userHandle
    var timer=NSTimer()
    var lastUpdated=0;
    var textLog=""
    var userHandle=""

    enum FileError : ErrorType {
        case Invalid
    }
    
    @IBAction func login(sender: AnyObject) {
        //socket variables
        addr = String(serverField.stringValue)
        
        //user variables and user defaults
        let userString=String(chatHandleField.stringValue)+"\n"
        let prefs = NSUserDefaults.standardUserDefaults()
        prefs.setObject(addr, forKey: "addr")
        prefs.setObject(userString, forKey: "user")
        
        //sets userHandle
        userHandle=String(chatHandleField.stringValue).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        //open socket
        var result=try NSStream.getStreamsToHostWithName(addr, port: port, inputStream: &inp, outputStream: &out)
        let inputStream = inp!
        let outputStream = out!
        inputStream.open()
        outputStream.open()
        
        //sends type
        let typeString="newUser\n"
        let typeOut: [UInt8] = Array(typeString.utf8)
        outputStream.write(typeOut, maxLength: typeOut.count)
        
        //sends user
        let userOut: [UInt8] = Array(userString.utf8)
        outputStream.write(userOut, maxLength: userOut.count)

        //gets input
        let bufferSize = 1024
        var inputBuffer = Array<UInt8>(count:bufferSize, repeatedValue: 0)
        var bytesRead = inputStream.read(&inputBuffer, maxLength: bufferSize)
        
        //encode as string and print
        var str=NSString(bytes: inputBuffer, length: inputBuffer.count, encoding: NSUTF8StringEncoding)
        let welcome:String = "Welcome to "+(str! as String)+"!\n"
        
        //hides elements
        serverField.hidden=true
        chatHandleField.hidden=true
        loginButton.hidden=true
        loginButton.enabled=false
        logOutButton.hidden=false
        sendField.hidden=false
        sendButton.hidden=false
        sendButton.enabled=true
        chatField.hidden=false
        chatFieldText.string=welcome
        loggedInLabel.stringValue="Logged in as \(userHandle)"
        loggedInLabel.hidden=false
        
        //reads in text
        bytesRead = inputStream.read(&inputBuffer, maxLength: bufferSize)
        str=NSString(bytes: inputBuffer, length: inputBuffer.count, encoding: NSUTF8StringEncoding)
        chatFieldText.string=welcome+(str! as String)
        textLog=chatFieldText.string!

        //set to default
        self.serverField.becomeFirstResponder()
        
        //close socket
        inputStream.close()
        outputStream.close()
        
        //calls timer
        timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(ViewController.updateTimer), userInfo: nil, repeats: true)
    }
    
    @IBAction func logOut(sender: AnyObject) {
        serverField.hidden=false
        chatHandleField.hidden=false
        loginButton.hidden=false
        loginButton.enabled=true
        logOutButton.hidden=true
        chatField.hidden=true
        sendField.hidden=true
        sendButton.hidden=true
        loggedInLabel.hidden=true
        timer.invalidate()
    }

    @IBAction func send(sender: AnyObject) {
        //open socket
        var result=try NSStream.getStreamsToHostWithName(addr, port: port, inputStream: &inp, outputStream: &out)
        let inputStream = inp!
        let outputStream = out!
        inputStream.open()
        outputStream.open()
        
        //outputs type
        let typeString="chat\n"
        let typeOut: [UInt8] = Array(typeString.utf8)
        outputStream.write(typeOut, maxLength: typeOut.count)
        
        //outputs chat string
        let chatString=userHandle+": "+String(sendField.stringValue).stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())+"\n"
        let chatOut = Array(chatString.utf8)
        print (chatString)
        outputStream.write(chatOut, maxLength: chatOut.count)
        
        //close socket
        inputStream.close()
        outputStream.close()
        
        sendField.stringValue=""
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window!.title = "HackIRC"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //loads user defaults
        let prefs = NSUserDefaults.standardUserDefaults()
        if let user = prefs.stringForKey("user")
        {
            chatHandleField.stringValue=user
        }
        if let address = prefs.stringForKey("addr")
        {
            serverField.stringValue=address
        }
    }

    override var representedObject: AnyObject? { didSet
        {
        // Update the view, if already loaded.
        }
    }
    
    func updateTimer()
    {
        //open socket
        var result=try NSStream.getStreamsToHostWithName(addr, port: port, inputStream: &inp, outputStream: &out)
        let inputStream = inp!
        let outputStream = out!
        inputStream.open()
        outputStream.open()
        
        //outputs type
        let typeString="lastTime\n"
        let typeOut: [UInt8] = Array(typeString.utf8)
        outputStream.write(typeOut, maxLength: typeOut.count)
        
        //gets input
        let bufferSize = 1024
        var inputBuffer = Array<UInt8>(count:bufferSize, repeatedValue: 0)
        var bytesRead = inputStream.read(&inputBuffer, maxLength: bufferSize)
        //encode as string and print
        let str=NSString(bytes: inputBuffer, length: inputBuffer.count, encoding: NSUTF8StringEncoding)
        let lastTimeString = str!.stringByReplacingOccurrencesOfString("\0", withString: "")
        let lastTimeInt: Int=Int(lastTimeString)!
        
        //close socket
        inputStream.close()
        outputStream.close()
        
        if (lastTimeInt > lastUpdated)
        {
            lastUpdated=lastTimeInt
            updateChat()
        }
    }
    
    func updateChat()
    {
        //open socket
        var result=try NSStream.getStreamsToHostWithName(addr, port: port, inputStream: &inp, outputStream: &out)
        let inputStream = inp!
        let outputStream = out!
        inputStream.open()
        outputStream.open()
        
        //outputs type
        let typeString="update\n"
        let typeOut: [UInt8] = Array(typeString.utf8)
        outputStream.write(typeOut, maxLength: typeOut.count)
        
        //gets input
        let bufferSize = 1024
        var inputBuffer = Array<UInt8>(count:bufferSize, repeatedValue: 0)
        var bytesRead = inputStream.read(&inputBuffer, maxLength: bufferSize)
        //encode as string and print
        let str=NSString(bytes: inputBuffer, length: inputBuffer.count, encoding: NSUTF8StringEncoding)
        
        //textLog=textLog+(str! as String) as String
        chatFieldText.string=str! as String
        chatFieldText.scrollToEndOfDocument(nil)
    }
}

