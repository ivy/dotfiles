#!/usr/bin/env bats

load 'test_helper'

setup() {
    # Call the test_helper setup first to get TEST_TMPDIR
    TEST_TMPDIR=$(mktemp -d)
    export TEST_TMPDIR
    
    export TEST_PROJECTS_DIR="$TEST_TMPDIR/projects"
    export PROJECTS_DIR="$TEST_PROJECTS_DIR"
    mkdir -p "$TEST_PROJECTS_DIR"
    
    # Copy the e script to temp location for testing
    export E_SCRIPT="$TEST_TMPDIR/e"
    cp "$PWD/home/dot_local/bin/executable_e" "$E_SCRIPT"
    chmod +x "$E_SCRIPT"
}

teardown() {
    unset PROJECTS_DIR GITHUB_USER GITHUB_ORGS
    rm -rf "$TEST_TMPDIR"
}

@test "e script exists and is executable" {
    [[ -f "$PWD/home/dot_local/bin/executable_e" ]]
    [[ -x "$PWD/home/dot_local/bin/executable_e" ]]
}

@test "get_potential_orgs returns expected organizations in order" {
    # Test with GITHUB_USER and GITHUB_ORGS set
    export GITHUB_USER="testuser"
    export GITHUB_ORGS="org1,org2,org3"
    
    # Source the functions
    source "$E_SCRIPT"
    
    local orgs
    orgs=$(get_potential_orgs)
    
    # Should include testuser first, then orgs from GITHUB_ORGS, then system user
    echo "$orgs" | head -1 | grep -q "testuser"
    echo "$orgs" | grep -q "org1"
    echo "$orgs" | grep -q "org2"
    echo "$orgs" | grep -q "org3"
    echo "$orgs" | tail -1 | grep -q "$USER"
}

@test "get_potential_orgs handles comma-delimited GITHUB_ORGS" {
    export GITHUB_ORGS="  org1  , org2,org3  "
    unset GITHUB_USER
    
    source "$E_SCRIPT"
    local orgs
    orgs=$(get_potential_orgs)
    
    # Should properly trim whitespace
    echo "$orgs" | grep -q "^org1$"
    echo "$orgs" | grep -q "^org2$"  
    echo "$orgs" | grep -q "^org3$"
}

@test "find_existing_repo finds repository when it exists" {
    # Create test repo structure
    mkdir -p "$TEST_PROJECTS_DIR/testorg/testrepo"
    
    export GITHUB_USER="testorg"
    source "$E_SCRIPT"
    
    local result
    result=$(find_existing_repo "testrepo")
    [[ "$result" == "testorg/testrepo" ]]
}

@test "find_existing_repo returns error when repo not found" {
    export GITHUB_USER="testorg"
    source "$E_SCRIPT"
    
    run find_existing_repo "nonexistent"
    [[ $status -ne 0 ]]
}

@test "find_existing_repo checks multiple orgs in priority order" {
    # Create repos in different orgs
    mkdir -p "$TEST_PROJECTS_DIR/org1/testrepo"
    mkdir -p "$TEST_PROJECTS_DIR/org2/testrepo"
    
    export GITHUB_USER="org1"
    export GITHUB_ORGS="org2,org3"
    source "$E_SCRIPT"
    
    # Should find in org1 first (GITHUB_USER takes priority)
    local result
    result=$(find_existing_repo "testrepo")
    [[ "$result" == "org1/testrepo" ]]
}

@test "e with ORG/REPO format uses exact path" {
    mkdir -p "$TEST_PROJECTS_DIR/specificorg/specificrepo"
    
    # Mock claude command to avoid actual execution
    export PATH="$TEST_TMPDIR:$PATH"
    echo '#!/bin/bash\necho "Mock claude started in $(pwd)"' > "$TEST_TMPDIR/claude"
    chmod +x "$TEST_TMPDIR/claude"
    
    run "$E_SCRIPT" "specificorg/specificrepo"
    [[ $status -eq 0 ]]
    [[ "$output" == *"specificorg/specificrepo"* ]]
}

@test "e with just REPO searches across organizations" {
    mkdir -p "$TEST_PROJECTS_DIR/myorg/myrepo"
    export GITHUB_USER="myorg"
    
    # Mock claude command
    export PATH="$TEST_TMPDIR:$PATH"
    echo '#!/bin/bash\necho "Mock claude started in $(pwd)"' > "$TEST_TMPDIR/claude"
    chmod +x "$TEST_TMPDIR/claude"
    
    run "$E_SCRIPT" "myrepo"
    [[ $status -eq 0 ]]
    [[ "$output" == *"Found existing repository: myorg/myrepo"* ]]
}

@test "e handles missing claude command gracefully" {
    mkdir -p "$TEST_PROJECTS_DIR/testorg/testrepo"
    export GITHUB_USER="testorg"
    
    # Ensure claude is not in PATH
    export PATH="/bin:/usr/bin"
    
    run "$E_SCRIPT" "testrepo"
    [[ $status -eq 0 ]]
    [[ "$output" == *"'claude' command not found"* ]]
    [[ "$output" == *"Current directory:"* ]]
}

@test "e creates projects directory if it doesn't exist" {
    export PROJECTS_DIR="$TEST_TMPDIR/newprojects"
    [[ ! -d "$PROJECTS_DIR" ]]
    
    mkdir -p "$TEST_TMPDIR/someorg/somerepo"  # This should fail, testing the mkdir -p logic
    
    # Source just to trigger the mkdir -p in the script
    source "$E_SCRIPT"
    [[ -d "$PROJECTS_DIR" ]]
}

@test "get_github_user returns user from gh config when available" {
    # Mock gh command
    export PATH="$TEST_TMPDIR:$PATH"
    cat > "$TEST_TMPDIR/gh" << 'EOF'
#!/bin/bash
case "$*" in
    "config get -h github.com user")
        echo "gh-testuser"
        exit 0
        ;;
    *)
        exit 1
        ;;
esac
EOF
    chmod +x "$TEST_TMPDIR/gh"
    
    source "$E_SCRIPT"
    local result
    result=$(get_github_user)
    [[ "$result" == "gh-testuser" ]]
}

@test "get_github_user fails gracefully when gh not available" {
    # Ensure gh is not in PATH
    export PATH="/bin:/usr/bin"
    
    source "$E_SCRIPT"
    run get_github_user
    [[ $status -ne 0 ]]
}