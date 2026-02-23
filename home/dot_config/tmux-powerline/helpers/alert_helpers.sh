# shellcheck shell=bash
# Shared helpers for notification rail color escalation.
# Sourced by theme files after palette variables are defined.

# Cross-platform CPU core count.
tp_cpu_count() {
	if command -v sysctl >/dev/null 2>&1; then
		sysctl -n hw.ncpu 2>/dev/null && return
	fi
	if command -v nproc >/dev/null 2>&1; then
		nproc 2>/dev/null && return
	fi
	echo 1
}

# Echo a palette color based on 1-min load average severity.
# Returns: $yellow (> cores), $red (> 2x cores), $surface0 (normal).
tp_alert_color_load() {
	local load cores
	load=$(uptime | sed 's/.*load average[s]*: *\([0-9.]*\).*/\1/')
	cores=$(tp_cpu_count)
	local double_cores
	double_cores=$(echo "$cores * 2" | bc -l)

	if echo "$load > $double_cores" | bc -l | grep -q '^1'; then
		echo "$red"
	elif echo "$load > $cores" | bc -l | grep -q '^1'; then
		echo "$yellow"
	else
		echo "$surface0"
	fi
}

# Echo a palette color based on memory usage severity.
# Returns: $red (>=90%), $yellow (>=80%), $surface0 (normal).
tp_alert_color_mem() {
	if [ "$(tp_mem_used_percentage_at_least 90)" = "1" ]; then
		echo "$red"
	elif [ "$(tp_mem_used_percentage_at_least 80)" = "1" ]; then
		echo "$yellow"
	else
		echo "$surface0"
	fi
}

# Echo a palette color based on root filesystem usage severity.
# Returns: $red (>=95%), $yellow (>=85%), $surface0 (normal).
tp_alert_color_disk() {
	local pct
	pct=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
	if [ "$pct" -ge 95 ] 2>/dev/null; then
		echo "$red"
	elif [ "$pct" -ge 85 ] 2>/dev/null; then
		echo "$yellow"
	else
		echo "$surface0"
	fi
}
