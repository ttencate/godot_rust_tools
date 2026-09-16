#!/usr/bin/env bash

set -euo pipefail

if [[ $# != 1 ]]; then
	echo "Usage:  $0 VERSION" >&2
	exit 2
fi
version="$1"

cd "$(dirname "$0")"/..

output_file="/tmp/rust_tools_${version}.zip"

echo "Packaging release. Included files:" >&2
git archive --verbose --format=zip --output="$output_file" "$version"
echo "Created $output_file" >&2
