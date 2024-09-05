import Foundation

func fetchTemplateProject(in directory: URL, directoryName: String) async throws(CLIError) {
    let spaceTemplateRepoUrl = "git@github.com:gfusee/space-template.git"
    
    let fileManager = FileManager.default
    
    try await runInTerminal(
        currentDirectoryURL: directory,
        command: "git clone \(spaceTemplateRepoUrl) \(directoryName)"
    )
}
