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
    
    try await fetchTemplateProject(in: pwd, directoryName: name)
    
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
    
    let adderTemplateContractPath = projectPath.appending(path: "Contracts/Adder")
    let namedTemplateContractPath = projectPath.appending(path: "Contracts/\(name)")
    
    do {
        try fileManager.moveItem(at: adderTemplateContractPath, to: namedTemplateContractPath)
    }
    catch {
        throw .fileManager(.cannotMoveFileOrDirectory(at: adderTemplateContractPath, to: namedTemplateContractPath))
    }
    
    let adderTestTemplateContractPath = namedTemplateContractPath.appending(path: "Tests/AdderTests")
    let namedTestTemplateContractPath = namedTemplateContractPath.appending(path: "Tests/\(name)Tests")
    
    do {
        try fileManager.moveItem(at: adderTestTemplateContractPath, to: namedTestTemplateContractPath)
    }
    catch {
        throw .fileManager(.cannotMoveFileOrDirectory(at: adderTestTemplateContractPath, to: namedTestTemplateContractPath))
    }
    
    let gitDirectoryPath = projectPath.appending(path: ".git")
    do {
        try fileManager.removeItem(at: gitDirectoryPath)
    } catch {
        throw .fileManager(.cannotRemoveFileOrDirectory(path: gitDirectoryPath))
    }
}
