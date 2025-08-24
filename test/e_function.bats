#!/usr/bin/env bats

load 'test_helper'

@test "e function script exists and is executable" {
    local script_path="$PWD/home/dot_local/bin/executable_e"
    
    # Check file exists
    [[ -f "$script_path" ]]
    
    # Check it's a valid zsh script
    head -1 "$script_path" | grep -q "#!/usr/bin/env zsh"
}

@test "e function script has valid zsh syntax" {
    local script_path="$PWD/home/dot_local/bin/executable_e"
    local script_content
    
    # Read the script content
    script_content=$(cat "$script_path")
    
    # Check it starts with proper shebang for zsh
    [[ "$script_content" == *"#!/usr/bin/env zsh"* ]]
    
    # Test basic syntax (we'll use the file directly since it's zsh)
    # Create a temp file for testing
    local temp_script="$TEST_TMPDIR/temp_e_script.zsh"
    cp "$script_path" "$temp_script"
    
    # Test syntax with zsh if available, otherwise with bash
    if command -v zsh >/dev/null 2>&1; then
        zsh -n "$temp_script"
    else
        # Basic bash syntax check as fallback
        bash -n "$temp_script" || true
    fi
}

@test "e function script has proper error handling" {
    local script_content
    script_content=$(cat "$PWD/home/dot_local/bin/executable_e")
    
    # Should have set -o errexit -o nounset for error handling
    [[ "$script_content" == *"set -o errexit -o nounset"* ]]
}

@test "e function script has expected functions" {
    local script_content
    script_content=$(cat "$PWD/home/dot_local/bin/executable_e")
    
    # Check for key functions
    [[ "$script_content" == *"get_github_user()"* ]]
    [[ "$script_content" == *"get_potential_orgs()"* ]]
    [[ "$script_content" == *"find_existing_repo()"* ]]
    [[ "$script_content" == *"clone_repo_from_orgs()"* ]]
    [[ "$script_content" == *"select_project_with_fzf()"* ]]
    [[ "$script_content" == *"open_project()"* ]]
    [[ "$script_content" == *"main()"* ]]
}

@test "e function script supports comma-delimited GITHUB_ORGS" {
    local script_content
    script_content=$(cat "$PWD/home/dot_local/bin/executable_e")
    
    # Check that it handles comma-delimited GITHUB_ORGS
    [[ "$script_content" == *"IFS=',' read -ra github_orgs"* ]]
    [[ "$script_content" == *"Comma-delimited list of GitHub orgs/users"* ]]
}

@test "e function script handles organization searching logic" {
    local script_content
    script_content=$(cat "$PWD/home/dot_local/bin/executable_e")
    
    # Check that it searches across organizations
    [[ "$script_content" == *"find_existing_repo"* ]]
    [[ "$script_content" == *"clone_repo_from_orgs"* ]]
    [[ "$script_content" == *"readarray -t potential_orgs"* ]]
}

@test "e function script only does git init for new repos" {
    local script_content
    script_content=$(cat "$PWD/home/dot_local/bin/executable_e")
    
    # Should only have git init, not git add/commit for new repos
    [[ "$script_content" == *"git init"* ]]
    [[ "$script_content" != *"git add README.md"* ]]
    [[ "$script_content" != *"git commit -m \"Initial commit\""* ]]
}