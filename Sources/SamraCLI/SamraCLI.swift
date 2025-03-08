import AssetCatalogWrapper
import Foundation
import ImageIO

// MARK: - Command & Option Definitions

enum Command: String, CaseIterable {
    case list
    case delete
    case add
    case edit
    case extract
}

enum Option: String, CaseIterable {
    case input = "i"
    case rendition = "r"
    case output = "o"
    case help = "h"
    case version = "v"
}

// MARK: - Error Definitions

enum CLIError: Error, LocalizedError {
    case missingCarFilePath
    case missingRenditionName
    case missingOutputPath
    case missingNewValuePath
    case unableToLoadCarFile(url: URL, error: Error)
    case renditionNotFound(name: String)
    case removalFailed(renditionName: String, error: Error)
    case editFailed(renditionName: String, error: Error)
    case saveFailed(url: URL, error: Error)
    case invalidInput(reason: String)
    case fileNotFound(path: String)
    case networkFailure(url: URL, statusCode: Int)
    case unexpected(description: String)

    var errorDescription: String? {
        switch self {
        case .missingCarFilePath:
            return "Error: Missing `.car` file path argument."
        case .missingRenditionName:
            return "Error: Missing rendition name argument."
        case .missingOutputPath:
            return "Error: Missing output path for extracted assets."
        case .missingNewValuePath:
            return "Error: Missing path for new rendition value."
        case .unableToLoadCarFile(let url, let error):
            return "Error: Unable to load `.car` file at \(url.path). \(error.localizedDescription)"
        case .renditionNotFound(let name):
            return "Error: Rendition with name '\(name)' not found in the asset catalog."
        case .removalFailed(let renditionName, let error):
            return
                "Error: Failed to remove rendition '\(renditionName)'. \(error.localizedDescription)"
        case .editFailed(let renditionName, let error):
            return
                "Error: Failed to edit rendition '\(renditionName)'. \(error.localizedDescription)"
        case .saveFailed(let url, let error):
            return
                "Error: Failed to save modified `.car` file to \(url.path). \(error.localizedDescription)"
        case .invalidInput(let reason):
            return "Error: \(reason)"
        case .fileNotFound(let path):
            return "Error: File not found at \(path)"
        case .networkFailure(let url, let statusCode):
            return
                "Error: Network failure when accessing \(url.absoluteString), status code: \(statusCode)"
        case .unexpected(let description):
            return "Error: \(description)"
        }
    }
}

// MARK: - Help Functions

func printHelp() {
    print("Asset Catalog CLI Tool")
    print("Usage: your_program [command] [options]")
    print("\nCommands:")
    print("  list       Lists all renditions in the asset catalog.")
    print("  delete     Deletes a rendition from the asset catalog.")
    print("  add        Adds a new rendition (not implemented yet).")
    print("  edit       Edits an existing rendition.")
    print("\nOptions:")
    print("  -i, --input     Specify input .car file path.")
    print("  -r, --rendition Specify rendition name to operate on.")
    print("  -o, --output    Specify output path for extracted assets")
    print("  -h, --help      Show help information.")
    print("  -v, --version   Show version information.")
}

func printVersion() {
    print("Asset Catalog CLI Tool v1.0")
    print("Built with AssetCatalogWrapper")
}

// MARK: - CLI Arguments Parsing

struct CommandLineOptions {
    var command: Command?
    var catalogPath: String?
    var renditionName: String?
    var newRenditionPath: String?
    var outputPath: String?
    var showHelp: Bool = false
    var showVersion: Bool = false
}

func parseArguments() throws -> CommandLineOptions {
    let arguments = CommandLine.arguments
    if arguments.count <= 1 {
        printHelp()
        throw CLIError.invalidInput(reason: "No arguments provided")
    }

    var options = CommandLineOptions()
    var index = 1  // Start from the second argument to skip program name

    // First check for a command
    if index < arguments.count {
        if let cmd = Command(rawValue: arguments[index]) {
            options.command = cmd
            index += 1
        }
    }

    // Then process remaining options
    while index < arguments.count {
        let arg = arguments[index]

        if arg.hasPrefix("-") {
            let option = arg.hasPrefix("--") ? String(arg.dropFirst(2)) : String(arg.dropFirst())

            switch option {
            case "i", "input":
                guard index + 1 < arguments.count else {
                    throw CLIError.invalidInput(
                        reason: "-i or --input option requires a path argument")
                }
                options.catalogPath = arguments[index + 1]
                index += 2

            case "r", "rendition":
                guard index + 1 < arguments.count else {
                    throw CLIError.invalidInput(
                        reason: "-r or --rendition option requires a name argument")
                }
                if options.command == Command.edit {
                    let command = arguments[index + 1]
                    let components = command.split(separator: "=")
                    options.renditionName = String(components[0])  //First value should be name
                    options.newRenditionPath = String(components[1])  //Second should be new path
                } else {
                    options.renditionName = arguments[index + 1]  //Otherwise just name is needed
                }
                index += 2

            case "o", "output":
                guard index + 1 < arguments.count else {
                    throw CLIError.invalidInput(
                        reason: "-o or --output option requires a path argument")
                }
                options.outputPath = arguments[index + 1]
                index += 2

            case "h", "help":
                options.showHelp = true
                index += 1

            case "v", "version":
                options.showVersion = true
                index += 1

            default:
                throw CLIError.invalidInput(reason: "Unknown option: \(arg)")
            }
        } else {
            // If we didn't already get a command and this is a non-option arg, try as command
            if options.command == nil {
                if let cmd = Command(rawValue: arg) {
                    options.command = cmd
                } else {
                    throw CLIError.invalidInput(reason: "Unknown command: \(arg)")
                }
            } else {
                throw CLIError.invalidInput(reason: "Unexpected argument: \(arg)")
            }
            index += 1
        }
    }

    return options
}

// MARK: - Utility Functions

func loadAssetCatalog(at path: String) throws -> (CUICatalog, RenditionCollection) {
    guard FileManager.default.fileExists(atPath: path) else {
        throw CLIError.fileNotFound(path: path)
    }

    let fileURL = URL(fileURLWithPath: path)
    let catalogWrapper = AssetCatalogWrapper.shared

    do {
        return try catalogWrapper.renditions(forCarArchive: fileURL)
    } catch {
        throw CLIError.unableToLoadCarFile(url: fileURL, error: error)
    }
}

func findRendition(named name: String, in collection: RenditionCollection) throws -> Rendition {
    let allRenditions = collection.flatMap(\.renditions)
    guard let rendition = allRenditions.first(where: { $0.name == name }) else {
        throw CLIError.renditionNotFound(name: name)
    }
    return rendition
}

// MARK: - Command Handlers

func handleListCommand(carFilePath: String) throws {
    // print("Loading asset catalog from: \(carFilePath)")

    let (_, renditionCollection) = try loadAssetCatalog(at: carFilePath)

    // print(
    //     "Loaded asset catalog. Found \(renditionCollection.flatMap(\.renditions).count) renditions:\n"
    // )

    // Map asset types to appropriate nerdfont icons
    func getNerdFontIcon(for type: RenditionType) -> String {
        switch type {
        case .image:
            return "󰋩 "  // nf-md-image
        case .icon:
            return ""  // nf-md-image
        case .color:
            return "󰏘 "  // nf-md-palette
        case .svg:
            return "󰰶 "  // nf-md-vector_curve
        case .pdf:
            return "󰈦 "  // nf-md-file_pdf
        case .imageSet:
            return "󰋯"
        default:
            return "󰈔 "  // nf-md-file generic file icon
        }
    }

    // Print all renditions grouped by type
    for (type, renditions) in renditionCollection {
        let icon = getNerdFontIcon(for: type)
        print("\u{001B}[1m\(type.description)s\u{001B}[0m")
        for rendition in renditions {
            print("  \(icon)\(rendition.name)")
        }
        print("")
    }
}

func handleDeleteCommand(carFilePath: String, renditionName: String) throws {
    let carFileURL = URL(fileURLWithPath: carFilePath)
    // print("Loading asset catalog from: \(carFileURL.path)")

    let (catalog, renditionCollection) = try loadAssetCatalog(at: carFilePath)
    let renditionToRemove = try findRendition(named: renditionName, in: renditionCollection)

    print(
        "Found rendition '\(renditionToRemove.name)' of type '\(renditionToRemove.type.description)'."
    )
    print("Removing rendition...")

    do {
        try catalog.removeItem(renditionToRemove, fileURL: carFileURL)
        print("Successfully removed rendition '\(renditionToRemove.name)'.")
        print("Modified asset catalog saved to: \(carFileURL.path)")
    } catch {
        throw CLIError.removalFailed(renditionName: renditionName, error: error)
    }
}

func handleEditCommand(carFilePath: String, renditionName: String, newValuePath: String) throws {
    let carFileURL = URL(fileURLWithPath: carFilePath)
    let newValueURL = URL(fileURLWithPath: newValuePath)

    guard FileManager.default.fileExists(atPath: newValuePath) else {
        throw CLIError.fileNotFound(path: newValuePath)
    }

    print("Loading asset catalog from: \(carFileURL.path)")

    let (catalog, renditionCollection) = try loadAssetCatalog(at: carFilePath)
    let renditionToEdit = try findRendition(named: renditionName, in: renditionCollection)

    print(
        "Found rendition '\(renditionToEdit.name)' of type '\(renditionToEdit.type.description)'.")
    print("Updating rendition with new content from: \(newValueURL.path)")

    // Create new representation from file
    // This is a simplified example - actual implementation would need to handle
    // different file types (images, colors, etc) appropriately
    guard let newImage = try? CGImage.loadFromURL(newValueURL) else {
        throw CLIError.invalidInput(reason: "Could not load image from \(newValuePath)")
    }

    let newRepresentation = Rendition.Representation.image(newImage)

    do {
        try catalog.editItem(renditionToEdit, fileURL: carFileURL, to: newRepresentation)
        print("Successfully updated rendition '\(renditionToEdit.name)'.")
        print("Modified asset catalog saved to: \(carFileURL.path)")
    } catch {
        throw CLIError.editFailed(renditionName: renditionName, error: error)
    }
}

func handleExtractCommand(carFilePath: String, outputPath: String, specificRendition: String? = nil)
    throws
{
    let carFileURL = URL(fileURLWithPath: carFilePath)
    let outputURL = URL(fileURLWithPath: outputPath)

    // Create output directory if it doesn't exist
    if !FileManager.default.fileExists(atPath: outputPath) {
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
    }

    print("Loading asset catalog from: \(carFileURL.path)")

    let (_, renditionCollection) = try loadAssetCatalog(at: carFilePath)
    let catalogWrapper = AssetCatalogWrapper.shared

    // If a specific rendition is requested, filter the collection
    if let specificName = specificRendition {
        // Find the rendition by name, TODO: for use in updated lib
        let rendition = try findRendition(named: specificName, in: renditionCollection)

        print("Extracting rendition: \(specificName)")
        try catalogWrapper.extractFile(inputRendition: rendition, to: outputURL)
        print("Successfully extracted rendition to: \(outputURL.path)")
    } else {
        // Extract all renditions
        print("Extracting all renditions...")
        try catalogWrapper.extract(collection: renditionCollection, to: outputURL)
        print("Successfully extracted all renditions to: \(outputURL.path)")
    }
}

// MARK: - Main Functionality

func run() throws {
    let options = try parseArguments()

    // Handle help and version options first
    if options.showHelp {
        printHelp()
        return
    }

    if options.showVersion {
        printVersion()
        return
    }

    guard let command = options.command else {
        printHelp()
        return
    }

    // Process commands
    switch command {
    case .list:
        guard let carFilePath = options.catalogPath else {
            throw CLIError.missingCarFilePath
        }
        try handleListCommand(carFilePath: carFilePath)

    case .delete:
        guard let carFilePath = options.catalogPath else {
            throw CLIError.missingCarFilePath
        }
        guard let renditionName = options.renditionName else {
            throw CLIError.missingRenditionName
        }
        try handleDeleteCommand(carFilePath: carFilePath, renditionName: renditionName)

    case .edit:
        guard let carFilePath = options.catalogPath else {
            throw CLIError.missingCarFilePath
        }
        guard let renditionName = options.renditionName else {
            throw CLIError.missingRenditionName
        }
        guard let newValuePath = options.newRenditionPath else {
            throw CLIError.missingNewValuePath
        }
        try handleEditCommand(
            carFilePath: carFilePath, renditionName: renditionName, newValuePath: newValuePath)

    case .add:
        print("Add command not implemented yet.")

    case .extract:
        guard let carPath = options.catalogPath else {
            throw CLIError.missingCarFilePath
        }

        guard let renditionName = options.renditionName else {
            throw CLIError.missingRenditionName
        }

        guard let output = options.outputPath else {
            throw CLIError.missingOutputPath
        }

        try handleExtractCommand(
            carFilePath: carPath, outputPath: output, specificRendition: renditionName)
    }

}

// MARK: - CGImage Extensions

extension CGImage {
    static func loadFromURL(_ url: URL) throws -> CGImage? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        return CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    }
}

// MARK: - Execution

do {
    try run()
} catch {
    if let cliError = error as? CLIError {
        print(cliError.localizedDescription)
    } else {
        print("An unexpected error occurred: \(error.localizedDescription)")
    }
    exit(1)
}

exit(0)
