import Foundation

func fetchTemplateProject(in directory: URL, directoryName: String) async throws(CLIError) {
    let spaceTemplateRepoUrl = "https://github.com/gfusee/space-template.git"
    
    _ = try await runInTerminal(
        currentDirectoryURL: directory,
        command: "git clone \(spaceTemplateRepoUrl) \(directoryName)"
    )
}
