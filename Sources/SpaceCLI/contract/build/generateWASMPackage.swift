import Workspace
import Basics
import PackageModel
import PackageGraph

fileprivate struct DummyError: Error {}

// TODO: automate this with a CI or by cloning the repo and retrieving the tags
let versionToHash: [String : String] = [
    "0.0.1" : "88563121484d503df1d1e0e3874b4c8f387bd1c2"
]

fileprivate func retrieveManifest(sourcePackagePath: String) throws(CLIError) -> Manifest {
    let sourcePackageAbsolutePath: AbsolutePath
    let workspace: Workspace
    do {
        sourcePackageAbsolutePath = try AbsolutePath(validating: sourcePackagePath)
        workspace = try Workspace(forRootPackage: sourcePackageAbsolutePath)
        
        let observability = ObservabilitySystem({ print("\($0): \($1)") })
        var result: Result<Manifest, any Error>? = nil
        workspace.loadRootManifest(at: sourcePackageAbsolutePath, observabilityScope: observability.topScope) { result = $0 }
        
        while result == nil {}
        
        switch result! {
        case .success(let manifest):
            return manifest
        case .failure(let error):
            throw DummyError()
        }
    } catch {
        let manifestPath = "\(sourcePackagePath)/Package.swift"
        throw .manifest(.cannotReadManifest(path: manifestPath))
    }
}

/// Generates the code of a Package.swift containing the contract target, ready for WASM compilation
func generateWASMPackage(sourcePackagePath: String, target: String) throws(CLIError) -> (generatedPackage: String, spaceHash: String) {
    let manifestPath = "\(sourcePackagePath)/Package.swift"
    let manifest = try retrieveManifest(sourcePackagePath: sourcePackagePath)
    let packageDependencies = manifest.dependencies
    let spaceDependency = packageDependencies.first { print($0.nameForModuleDependencyResolutionOnly); return $0.nameForModuleDependencyResolutionOnly.lowercased(with: .current) == "space" }
    guard let spaceDependency = spaceDependency else {
        throw .manifest(.spaceDependencyNotFound(manifestPath: manifestPath))
    }
    
    guard case .sourceControl(let spaceSourceControlInfo) = spaceDependency else {
        throw .manifest(.spaceDependencyShouldBeAGitRepository(manifestPath: manifestPath))
    }
    
    let spaceUrl: String
    switch spaceSourceControlInfo.location {
    case .local(let setting):
        spaceUrl = setting.pathString
    case .remote(let settings):
        spaceUrl = "/space"
        // TODO: use "spaceUrl = settings.absoluteString" instead when space is public
    }
    
    let spaceRequirements: PackageRequirement
    do {
        spaceRequirements = try spaceDependency.toConstraintRequirement()
    } catch {
        throw .manifest(.cannotReadDependencyRequirement(manifestPath: manifestPath, dependency: "Space"))
    }
    
    guard case .versionSet(.exact(let version)) = spaceRequirements else {
        throw .manifest(.spaceDependencyShouldHaveExactVersion(manifestPath: manifestPath))
    }
    
    let versionString = "\(version.major).\(version.minor).\(version.patch)"
    guard let hash = versionToHash[versionString] else {
        throw .manifest(.invalidSpaceVersion(
            manifestPath: manifestPath,
            versionFound: versionString,
            validVersions: Array(versionToHash.keys)
        ))
    }
    
    guard let targetInfo = manifest.targetMap[target] else {
        throw .manifest(.targetNotFound(manifestPath: sourcePackagePath, target: target))
    }
    
    let targetPath = if let targetPath = targetInfo.path {
        "path: \"\(targetPath)\","
    } else {
        ""
    }
    
    let packageCode = """
    // swift-tools-version: 5.10
    // The swift-tools-version declares the minimum version of Swift required to build this package.

    import PackageDescription

    let package = Package(
        name: "\(target)Wasm",
        platforms: [
            .macOS(.v14)
        ],
        products: [],
        dependencies: [
            .package(url: "\(spaceUrl)", revision: "\(hash)")
        ],
        targets: [
            // Targets are the basic building blocks of a package, defining a module or a test suite.
            // Targets can depend on other targets in this package and products from dependencies.
            .target(
                name: "\(target)",
                dependencies: [
                    .product(name: "Space", package: "Space")
                ],
                \(targetPath)
                swiftSettings: [
                    .unsafeFlags([
                        "-gnone",
                        "-Osize",
                        "-enable-experimental-feature",
                        "Extern",
                        "-enable-experimental-feature",
                        "Embedded",
                        "-Xcc",
                        "-fdeclspec",
                        "-whole-module-optimization",
                        "-D",
                        "WASM",
                        "-disable-stack-protector"
                    ])
                ]
            )
        ]
    )
    """
    
    return (generatedPackage: packageCode, spaceHash: hash)
}
