# Main commands
set -l commands list delete add edit extract

# Options
set -l options -i --input -r --rendition -o --output -h --help -v --version

function __samra_needs_command
    set -l cmd (commandline -opc)
    if [ (count $cmd) -eq 1 ]
        return 0
    end
    return 1
end

function __samra_using_command
    set -l cmd (commandline -opc)
    if [ (count $cmd) -gt 1 ]
        if [ $argv[1] = $cmd[2] ]
            return 0
        end
    end
    return 1
end

# Complete the main command
complete -f -c samra -n __samra_needs_command -a list -d "Lists all renditions in the asset catalog"
complete -f -c samra -n __samra_needs_command -a delete -d "Deletes a rendition from the asset catalog"
complete -f -c samra -n __samra_needs_command -a add -d "Adds a new rendition (not implemented yet)"
complete -f -c samra -n __samra_needs_command -a edit -d "Edits an existing rendition"
complete -f -c samra -n __samra_needs_command -a extract -d "Extract renditions from the asset catalog"

# Options for all commands with integrated file filtering
complete -f -c samra -s i -l input -d "Specify input .car file path" -r -a "*.car"
complete -f -c samra -s h -l help -d "Show help information"
complete -f -c samra -s v -l version -d "Show version information"

# Command-specific options
complete -f -c samra -n "__samra_using_command delete" -s r -l rendition -d "Specify rendition name to operate on" -r
complete -f -c samra -n "__samra_using_command edit" -s r -l rendition -d "Specify rendition name to operate on" -r
complete -f -c samra -n "__samra_using_command extract" -s r -l rendition -d "Specify rendition name to operate on" -r

# For extract command that requires an output path
complete -f -c samra -n "__samra_using_command extract" -s o -l output -d "Specify output path for extracted assets" -r -a "(__fish_complete_directories)"

# Image files for edit command's new value
complete -f -c samra -n "__samra_using_command edit" -a "*.png *.jpg *.jpeg *.tiff *.pdf *.svg" -d "Image file"
