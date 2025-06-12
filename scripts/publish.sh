#!/bin/bash

# Function to increment version
increment_version() {
    local version=$1
    local type=$2
    
    IFS='.' read -r -a parts <<< "$version"
    case $type in
        "major")
            parts[0]=$((parts[0] + 1))
            parts[1]=0
            parts[2]=0
            ;;
        "minor")
            parts[1]=$((parts[1] + 1))
            parts[2]=0
            ;;
        "patch")
            parts[2]=$((parts[2] + 1))
            ;;
    esac
    
    echo "${parts[0]}.${parts[1]}.${parts[2]}"
}

# Get current version from pubspec.yaml
current_version=$(grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d "'" | tr -d '"')

# Ask for version increment type
echo "Current version: $current_version"
echo "Select version increment type:"
echo "1) Major (x.0.0)"
echo "2) Minor (0.x.0)"
echo "3) Patch (0.0.x)"
read -p "Enter choice (1-3): " choice

case $choice in
    1) new_version=$(increment_version "$current_version" "major") ;;
    2) new_version=$(increment_version "$current_version" "minor") ;;
    3) new_version=$(increment_version "$current_version" "patch") ;;
    *) echo "Invalid choice"; exit 1 ;;
esac

# Update version in pubspec.yaml
sed -i '' "s/^version: .*/version: $new_version/" pubspec.yaml

# Update CHANGELOG.md
echo "## $new_version ($(date +%Y-%m-%d))" > temp_changelog.md
echo "" >> temp_changelog.md
echo "### Changes" >> temp_changelog.md
echo "" >> temp_changelog.md
cat CHANGELOG.md >> temp_changelog.md
mv temp_changelog.md CHANGELOG.md

# Run dry run
echo "Running pub publish --dry-run..."
dart pub publish --dry-run

# Ask for confirmation
read -p "Do you want to publish version $new_version? (y/n): " confirm
if [ "$confirm" = "y" ]; then
    echo "Publishing version $new_version..."
    dart pub publish
else
    echo "Publishing cancelled. Reverting changes..."
    git checkout pubspec.yaml CHANGELOG.md
fi 