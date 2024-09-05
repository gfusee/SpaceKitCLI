import Foundation

func fetchSpaceRepository(hash: String) async throws(CLIError) -> URL {
    let spaceRepoUrl = "git@github.com:gfusee/space.git"
    let spaceRepoName = "SpaceFramework"
    
    let permanentStorageDirectory = try getPermanentStorageDirectory()
    let spaceRepoPath = permanentStorageDirectory.appending(path: spaceRepoName)
    
    let fileManager = FileManager.default
    
    if !fileManager.fileExists(atPath: spaceRepoPath.path) {
        // We clone the framework and name the "SpaceFramework" for convenience
        try await runInTerminal(
            currentDirectoryURL: permanentStorageDirectory,
            command: "git clone \(spaceRepoUrl) \(spaceRepoName)"
        )
    }
    
    do {
        try await runInTerminal(
            currentDirectoryURL: spaceRepoPath,
            command: "git checkout \(hash)"
        )
    } catch {
        try await runInTerminal(
            currentDirectoryURL: spaceRepoPath,
            command: "git pull --ff"
        )
        
        try await runInTerminal(
            currentDirectoryURL: spaceRepoPath,
            command: "git checkout \(hash)"
        )
    }
    
    return spaceRepoPath
}
