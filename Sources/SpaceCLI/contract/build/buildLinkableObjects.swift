import Foundation

fileprivate struct ObjectFileInfo {
    let filename: String
    let directory: URL
    let outputName: String
}

func buildLinkableObjects(spaceHash: String) async throws(CLIError) -> [URL] {
    let spaceRepoPath = try await fetchSpaceRepository(hash: spaceHash)
    
    let allObjectFileInfo = [
        ObjectFileInfo(
            filename: "memcpy.c",
            directory: spaceRepoPath.appending(path: "Utils/Memory"),
            outputName: "memcpy.o"
        )
    ]
    
    let outputDirectory = try getLinkableObjectsDirectory()
    var resultFilePaths: [URL] = []
    
    let fileManager = FileManager.default
    
    for objectFileInfo in allObjectFileInfo {
        try await runInTerminal(
            currentDirectoryURL: objectFileInfo.directory,
            command: "clang --target=wasm32 -O3 -c -o \(objectFileInfo.outputName) \(objectFileInfo.filename)"
        )
        
        let outputFilePath = outputDirectory.appending(path: objectFileInfo.outputName)
        if fileManager.fileExists(atPath: outputFilePath.path) {
            do {
                try fileManager.removeItem(at: outputFilePath)
            } catch {
                throw .fileManager(.cannotRemoveFileOrDirectory(path: outputFilePath))
            }
        }
        
        let compiledObjectPath = objectFileInfo.directory.appending(path: objectFileInfo.outputName)
        
        do {
            try fileManager.copyItem(at: compiledObjectPath, to: outputFilePath)
        } catch {
            print(error)
            throw .fileManager(.cannotCopyFileOrDirectory(at: compiledObjectPath, to: outputFilePath))
        }
        
        resultFilePaths.append(outputFilePath)
    }
    
    // No need to compile libclang_rt.builtins-wasm32
    resultFilePaths.append(spaceRepoPath.appending(path: "Utils/Builtins/libclang_rt.builtins-wasm32.a"))
    
    return resultFilePaths
}
