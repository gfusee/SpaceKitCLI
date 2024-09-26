import AppKit

func runInTerminal(
    currentDirectoryURL: URL,
    command: String,
    environment: [String : String] = [:]
) async throws(CLIError) {
    let task = Process()
    
    task.currentDirectoryURL = currentDirectoryURL
    task.launchPath = "/bin/bash"
    
    var environment = environment
    environment["PATH"] = ProcessInfo.processInfo.environment["PATH"] ?? ""
    
    task.environment = environment
    task.arguments = ["-c", command]
    
    CurrentTerminalProcess.process = task
    
    do {
        print("INFO: Running \(command) in \(currentDirectoryURL.path)")
        try task.run()
        CurrentTerminalProcess.process = nil
    } catch {
        CurrentTerminalProcess.process = nil
        throw .common(.cannotRunCommand(command: command, directory: currentDirectoryURL.path, errorMessage: error.localizedDescription))
    }
    
    task.waitUntilExit()
    let status = task.terminationStatus
    guard status == 0 else {
        throw .common(.cannotRunCommand(command: command, directory: currentDirectoryURL.path, errorMessage: "Command exited with status code \(status)."))
    }
}

func runInDocker(
    hostVolumeURL: URL,
    destVolumeURL: URL,
    commands: [String],
    environment: [String : String] = [:],
    arguments: [String] = []
) async throws(CLIError) {
    var commandsWithInfo: [String] = []
    for command in commands {
        commandsWithInfo.append("""
        echo "Info: Running \(command) in Docker"
        """)
        
        commandsWithInfo.append(command)
    }
    
    let commandsWithInfoString = commandsWithInfo.joined(separator: "\n\n")
    let script = """
    #!/bin/zsh

    # Exit immediately if a command exits with a non-zero status
    set -e
    
    \(commandsWithInfoString)
    """
    
    try await runInTerminal(
        currentDirectoryURL: hostVolumeURL,
        command: """
                docker run --rm -v .:\(destVolumeURL.path) ghcr.io/gfusee/space-cli:0.0.1-beta-2 /bin/bash -c "echo '\(script.toBase64())' | base64 -d | /bin/bash"
                """,
        environment: environment
    )
}
