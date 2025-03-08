# Welcome
**NOTE**
I was meaning to make a pull request on the official Samra repo, but after noticing that they don't seem to have merged some others, I'm just putting this up here until I figure out swift development enough to truly fork and produce my own builds. (And hopefully get changes merged someday!)

There are completions for this tool as well! You'll have to move them to their respective directories, and I've only tested fish completions. Enjoy!

**Samra** is a command-line interface (CLI) for interacting with `.car` (Asset Catalog) files, commonly used in iOS, macOS, watchOS, and tvOS development. This tool allows you to inspect, modify, and extract assets directly from `.car` files without needing to open Xcode.

**Built using [AssetCatalogWrapper](https://github.com/NSAntoine/PrivateKits)** Please make a pull request over there for any features you feel might be missing so I can integrate! Otherwise this tool is at feature-parity

## Features

Samra supports the following commands:

  - **`list`**:  Lists all renditions (assets) within a `.car` file, categorized by type (image, color, etc.).
  - **`delete`**: Removes a specific rendition from a `.car` file.
  - **`edit`**: Replaces an existing rendition within a `.car` file with a new asset from a file path.
  - **`extract`**: Extracts assets from a `.car` file, either all assets or a specific rendition, to a designated output directory.

### Commands in Detail

  - **`list`**:

      - Lists all renditions present in the specified `.car` file.
      - **Usage:** `Samra list -i <path_to_.car_file>`
      - **Example:** `Samra list -i Assets.car`

  - **`delete`**:

      - Deletes a rendition with a given name from the specified `.car` file.
      - **Usage:** `Samra delete -i <path_to_.car_file> -r <rendition_name>`
      - **Example:** `Samra delete -i Assets.car -r "AppIcon-20x20@2x.png"`

  - **`edit`**:

      - Edits (replaces) a rendition with a new asset from a file path.
      - **Usage:** `Samra edit -i <path_to_.car_file> -r <rendition_name>=<path_to_new_asset>`
      - **Example:** `Samra edit -i Assets.car -r "AppIcon-20x20@2x.png=./new_icon.png"`

  - **`extract`**:

      - Extracts assets from the `.car` file.
      - Can extract all assets or a specific rendition.
      - **Usage (Extract All):** `Samra extract -i <path_to_.car_file> -o <output_path>`
      - **Usage (Extract Specific Rendition):** `Samra extract -i <path_to_.car_file> -o <output_path> -r <rendition_name>`
      - **Example (Extract All):** `Samra extract -i Assets.car -o extracted_assets`
      - **Example (Extract Specific Rendition):** `Samra extract -i Assets.car -o extracted_assets -r "LaunchImage.png"`

### Options

Samra uses the following options:

  - **`-i`, `--input <path_to_.car_file>`**:  Specifies the path to the input `.car` file. **Required** for most commands.
  - **`-r`, `--rendition <rendition_name>`**: Specifies the name of the rendition to operate on (delete, edit, extract specific). **Required** for `delete`, `edit`, and `extract` (when extracting a specific rendition). For `edit`, the format is `-r <rendition_name>=<path_to_new_asset>`.
  - **`-o`, `--output <output_path>`**: Specifies the output path for extracted assets. **Required** for `extract` command.
  - **`-h`, `--help`**: Shows the help information and usage instructions.
  - **`-v`, `--version`**: Shows the tool's version information.

## Installation

### Prerequisites

  - **Swift 5.0 or later**: Ensure you have Swift installed on your system. You can download it from [swift.org](https://www.google.com/url?sa=E&source=gmail&q=https://www.swift.org/download/).

### Building from Source

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/philocalyst/SamraCLI
    cd SamraCLI
    ```

2.  **Build the project using Swift Package Manager:**

    ```bash
    swift build -c release
    ```

3.  **Find the executable:**
    The executable `samra` will be located in the `.build/release` directory.

4.  **(Optional) Install globally:**
    You can copy the executable to a directory in your system's `PATH` (e.g., `/usr/local/bin`) to access it globally:

    ```bash
    sudo cp .build/release/samra /usr/local/bin/
    ```

## Usage Examples

**1. List all renditions in `Assets.car`:**

```bash
samra list -i Assets.car
```

**2. Delete the rendition named `OldIcon.png` from `Assets.car`:**

```bash
samra delete -i Assets.car -r "OldIcon.png"
```

**3. Replace the `AppIcon-20x20@2x.png` rendition in `Assets.car` with a new image from `new_icon.png`:**

```bash
samra edit -i Assets.car -r "AppIcon-20x20@2x.png=./path/to/new_icon.png"
```

**4. Extract all assets from `Assets.car` to a directory named `extracted_assets`:**

```bash
samra extract -i Assets.car -o extracted_assets
```

**5. Extract only the `LaunchImage.png` rendition from `Assets.car` to the `extracted_assets` directory:**
` bash samra extract -i Assets.car -o extracted_assets -r "LaunchImage.png"  `

## Error Handling

samra provides informative error messages for common issues. Some potential errors include:

  - **Missing `.car` file path**:  `Error: Missing \`.car\` file path argument.\`
  - **Missing rendition name**: `Error: Missing rendition name argument.`
  - **Missing output path**: `Error: Missing output path for extracted assets.`
  - **Rendition not found**: `Error: Rendition with name '<rendition_name>' not found in the asset catalog.`
  - **File not found**: `Error: File not found at <path>`
  - **Invalid input**: `Error: <reason>` (e.g., invalid option, missing argument for an option).
  - **Unable to load `.car` file**: `Error: Unable to load \`.car\` file at <path>. \<error\_description\>\`
  - **Failed to remove/edit/save rendition**: `Error: Failed to <action> rendition '<rendition_name>'. <error_description>`

Use the `-h` or `--help` option to display usage instructions if you encounter errors.

## Version

samra v1.0

## Contributing

Contributions are welcome\! Please feel free to submit pull requests or open issues for bug reports and feature requests. I need it! Do note though that most of those should be directed towards the [AssetCatalogWrapper](https://github.com/NSAntoine/PrivateKits) I use here.

## License
MIT
