#!/usr/bin/env bats

load test_helper

HOOK="${BATS_TEST_DIRNAME}/../home/dot_local/libexec/executable_block-adhoc-installers"

# Feed a command through the guard as PreToolUse JSON; echo "allow" when the hook
# emits nothing (defers) or the deny decision otherwise.
decision() {
	local out
	out="$(jq -cn --arg c "$1" '{tool_input: {command: $c}}' | bash "$HOOK")"
	if [[ -z "${out}" ]]; then
		echo "allow"
	else
		printf '%s' "${out}" | jq -r '.hookSpecificOutput.permissionDecision'
	fi
}

@test "denies ad-hoc installers and runners" {
	for cmd in \
		"npx cowsay" \
		"pnpm dlx create-app" \
		"yarn dlx foo" \
		"bunx vite" \
		"pipx run black" \
		"pipx install black" \
		"uvx ruff" \
		"uv tool install ruff" \
		"pip install requests" \
		"pip3 install requests" \
		"python3 -m pip install requests" \
		"npm install -g typescript" \
		"npm i -g typescript" \
		"gem install rubocop" \
		"brew install jq" \
		"apt-get install foo" \
		"dnf install foo" \
		"cargo install bat" \
		"go install golang.org/x/tools/gopls@latest"; do
		[ "$(decision "${cmd}")" = "deny" ] || {
			echo "expected deny for: ${cmd}"
			return 1
		}
	done
}

@test "allows legitimate non-install commands" {
	for cmd in \
		"npm test" \
		"npm run build" \
		"npm ci" \
		"npm view react version" \
		"pip show requests" \
		"pip index versions black" \
		"pipx list" \
		"mise install" \
		"mise use node@22" \
		"git status" \
		"ls -la"; do
		[ "$(decision "${cmd}")" = "allow" ] || {
			echo "expected allow for: ${cmd}"
			return 1
		}
	done
}

@test "catches installers in compound and env-prefixed commands" {
	[ "$(decision 'ls && npx create-app')" = "deny" ]
	[ "$(decision 'cd /tmp; pip install x')" = "deny" ]
	[ "$(decision 'FOO=1 npx y')" = "deny" ]
	[ "$(decision 'sudo apt install foo')" = "deny" ]
	[ "$(decision 'echo hi | npx z')" = "deny" ]
}

@test "deny reason redirects to /install without leaking the bypass" {
	local out
	out="$(jq -cn --arg c "npx x" '{tool_input: {command: $c}}' | bash "$HOOK")"
	[[ "$(printf '%s' "${out}" | jq -r '.hookSpecificOutput.permissionDecisionReason')" == *"/install"* ]]
	[[ "${out}" != *"CLAUDE_ALLOW_ADHOC_INSTALL"* ]]
}

@test "CLAUDE_ALLOW_ADHOC_INSTALL bypass defers to normal handling" {
	local out
	out="$(jq -cn --arg c "npx x" '{tool_input: {command: $c}}' | CLAUDE_ALLOW_ADHOC_INSTALL=1 bash "$HOOK")"
	[ -z "${out}" ]
}

@test "ignores non-bash input with no command" {
	local out
	out="$(printf '{"tool_input":{}}' | bash "$HOOK")"
	[ -z "${out}" ]
}
