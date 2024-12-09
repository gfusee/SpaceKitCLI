import Foundation
import Workspace
import Basics
import ArgumentParser

struct InitCommandOptions: ParsableArguments {
    @Argument(help: "The name of the directory which will be created.")
    var name: String
}

struct InitCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Create a new SpaceKit project in a new directory."
    )
    
    @OptionGroup var options: InitCommandOptions
    
    mutating func run() async throws {
        try await initializeProject(
            name: self.options.name
        )
    }
}

func initializeProject(
    name: String
) async throws(CLIError) {
    let fileManager = FileManager.default
    let pwd = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    
    let projectPath = pwd.appending(path: name)
    
    guard !fileManager.fileExists(atPath: projectPath.path) else {
        throw .projectInit(.directoryAlreadyExists(path: pwd.path))
    }
    
    try await fetchTemplateProject(
        in: pwd,
        directoryName: name,
        commitHash: "9450b643d81c5ed79b1ab267d96c8a1352b8a5f1"
    )
    
    let packageSwiftPath = projectPath.appending(path: "Package.swift")
    
    guard let packageSwiftContent = fileManager.contents(atPath: packageSwiftPath.path) else {
        throw .projectInit(.cannotReadPackageSwift(path: packageSwiftPath.path))
    }

    guard var packageSwiftContent = String(data: packageSwiftContent, encoding: .utf8) else {
        throw .projectInit(.cannotDecodePackageSwiftUsingUTF8(path: packageSwiftPath.path))
    }
    
    packageSwiftContent = packageSwiftContent
        .replacingOccurrences(of: "##PACKAGE_NAME##", with: name)
        .replacingOccurrences(of: "##TARGET_NAME##", with: name)
    
    fileManager.createFile(atPath: packageSwiftPath.path, contents: packageSwiftContent.data(using: .utf8))
    
    let adderTemplateContractPath = projectPath.appending(path: "Contracts/Counter")
    let namedTemplateContractPath = projectPath.appending(path: "Contracts/\(name)")
    
    do {
        try fileManager.moveItem(at: adderTemplateContractPath, to: namedTemplateContractPath)
    }
    catch {
        throw .fileManager(.cannotMoveFileOrDirectory(at: adderTemplateContractPath, to: namedTemplateContractPath))
    }
    
    let counterTestTemplateContractPath = namedTemplateContractPath.appending(path: "Tests/CounterTests")
    let namedTestTemplateContractPath = namedTemplateContractPath.appending(path: "Tests/\(name)Tests")
    
    do {
        try fileManager.moveItem(at: counterTestTemplateContractPath, to: namedTestTemplateContractPath)
    }
    catch {
        throw .fileManager(.cannotMoveFileOrDirectory(at: counterTestTemplateContractPath, to: namedTestTemplateContractPath))
    }
    
    let gitDirectoryPath = projectPath.appending(path: ".git")
    do {
        try fileManager.removeItem(at: gitDirectoryPath)
    } catch {
        throw .fileManager(.cannotRemoveFileOrDirectory(path: gitDirectoryPath))
    }
}
