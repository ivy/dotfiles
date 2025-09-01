#!/usr/bin/env bats

load test_helper

@test "renders correctly and produces valid shell syntax" {
    # Test our ACTUAL script renders to valid shell syntax
    local script_file="home/run_onchange_install-nodejs-tools.sh.tmpl"

    # Render our actual script (no template variables needed for this script)
    run chezmoi execute-template --file "$script_file"
    [ "$status" -eq 0 ]

    assert_script_structure "$output"
}

@test "script reads package.json and constructs pkg@version list" {
    # Test that the script contains the jq command for parsing package.json
    local script_file="home/run_onchange_install-nodejs-tools.sh.tmpl"
    
    run chezmoi execute-template --file "$script_file"
    [ "$status" -eq 0 ]
    
    # Check that script uses jq to parse devDependencies
    [[ "$output" == *"jq -r"* ]]
    [[ "$output" == *".devDependencies"* ]]
    [[ "$output" == *"to_entries"* ]]
    [[ "$output" == *"\(.key)@\(.value)"* ]]
}

@test "script uses npm hardening flags" {
    # Test that the script uses proper hardening flags
    local script_file="home/run_onchange_install-nodejs-tools.sh.tmpl"
    
    run chezmoi execute-template --file "$script_file"
    [ "$status" -eq 0 ]
    
    # Check for all hardening flags
    [[ "$output" == *"--ignore-scripts"* ]]
    [[ "$output" == *"--no-audit"* ]]
    [[ "$output" == *"--no-fund"* ]]
    [[ "$output" == *"--global"* ]]
}

@test "script checks for required tools availability" {
    # Test that the script checks for mise, node, and jq availability
    local script_file="home/run_onchange_install-nodejs-tools.sh.tmpl"
    
    run chezmoi execute-template --file "$script_file"
    [ "$status" -eq 0 ]
    
    # Check for mise availability check
    [[ "$output" == *"command -v mise"* ]]
    
    # Check for node availability via mise
    [[ "$output" == *"mise which node"* ]]
    
    # Check for jq availability via mise  
    [[ "$output" == *"mise which jq"* ]]
}

@test "script handles missing manifest gracefully" {
    # Test that the script handles missing package.json gracefully
    local script_file="home/run_onchange_install-nodejs-tools.sh.tmpl"
    
    run chezmoi execute-template --file "$script_file"
    [ "$status" -eq 0 ]
    
    # Check for manifest file check
    [[ "$output" == *'[ -f "$MANIFEST" ]'* ]]
    [[ "$output" == *"No package.json found"* ]]
}