import Foundation

func fetchTemplateProject(in directory: URL, directoryName: String) async throws(CLIError) {
    let spaceKitTemplateRepoUrl = "https://github.com/gfusee/SpaceKitTemplate.git"
    
    _ = try await runInTerminal(
        currentDirectoryURL: directory,
        command: "git clone \(spaceKitTemplateRepoUrl) \(directoryName)"
    )
}
