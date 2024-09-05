import AppKit

func runInTerminal(
    currentDirectoryURL: URL,
    command: String,
    environment: [String : String] = [:],
    arguments: [String] = []
) async throws(CLIError) {
    let task = Process()
    
    task.currentDirectoryURL = currentDirectoryURL
    task.launchPath = "/bin/bash"
    
    var environment = environment
    environment["PATH"] = ProcessInfo.processInfo.environment["PATH"] ?? ""
    
    task.environment = environment
    
    let fullCommand = "\(command) \(arguments.joined(separator: " "))"
    task.arguments = ["-c", fullCommand]
    
    CurrentTerminalProcess.process = task
    
    do {
        print("INFO: Running \(fullCommand) in \(currentDirectoryURL.path)")
        try task.run()
        CurrentTerminalProcess.process = nil
    } catch {
        CurrentTerminalProcess.process = nil
        throw .common(.cannotRunCommand(command: fullCommand, directory: currentDirectoryURL.path, errorMessage: error.localizedDescription))
    }
    
    task.waitUntilExit()
    let status = task.terminationStatus
    guard status == 0 else {
        throw .common(.cannotRunCommand(command: fullCommand, directory: currentDirectoryURL.path, errorMessage: "Command exited with status code \(status)."))
    }
}
