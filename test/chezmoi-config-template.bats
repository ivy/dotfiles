#!/usr/bin/env bats

load test_helper

setup() {
	CONFIG_FILE="${BATS_TEST_TMPDIR}/chezmoi.toml"
	cat >"$CONFIG_FILE" <<'TOML'
[data.git]
name = "Existing Name"
email = "existing@example.com"

[data.claude]
use_bedrock = true

[data.credentials]
codex = ""
claude_api = ""
buildkite = ""
ngrok = ""

[data.obsidian]
vault_path = "/tmp/vault"

[[data.claudeExtensionsExtra.mcpServers]]
name = "local-server"
transport = "stdio"
command = "/usr/local/bin/local-server"
args = ["mcp"]

[data.claudeExtensionsExtra.mcpServers.env]
LOCAL_TOKEN_PATH = "/run/token"
TOML
}

render() {
	chezmoi execute-template --init --config "$CONFIG_FILE" --file home/.chezmoi.toml.tmpl
}

@test "regenerating keeps machine-local Claude extensions" {
	run render
	[ "$status" -eq 0 ]

	local parsed
	parsed="$(yq -p toml -o json '.' <<<"$output")"
	[ "$(jq -r '.data.claudeExtensionsExtra.mcpServers[0].name' <<<"$parsed")" = "local-server" ]
	[ "$(jq -r '.data.claudeExtensionsExtra.mcpServers[0].env.LOCAL_TOKEN_PATH' <<<"$parsed")" = "/run/token" ]
}

@test "regenerating keeps the existing git identity" {
	run render
	[ "$status" -eq 0 ]

	local parsed
	parsed="$(yq -p toml -o json '.' <<<"$output")"
	[ "$(jq -r '.data.git.name' <<<"$parsed")" = "Existing Name" ]
	[ "$(jq -r '.data.git.email' <<<"$parsed")" = "existing@example.com" ]
}

@test "does not redirect mise away from its user config" {
	run render
	[ "$status" -eq 0 ]
	[[ "$output" != *"MISE_GLOBAL_CONFIG_FILE"* ]]
}
