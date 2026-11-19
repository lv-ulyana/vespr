cd /home/claude/vespr
git add -A && git -c user.name="Claude" -c user.email="noreply@anthropic.com" commit -qm "$1

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_014gfNJfnkC9T8fbke2Fq96Y"
# пушимо завжди: коміт міг уже зробити tool/quick.sh
git push -q origin HEAD:main
sleep 20
sha=$(git rev-parse HEAD)
until id=$(gh run list -L5 --workflow build.yml --json databaseId,headSha --jq ".[] | select(.headSha==\"$sha\") | .databaseId" | head -1); [ -n "$id" ]; do sleep 5; done
until gh run view $id --json jobs --jq '.jobs[] | "\(.name):\(.status):\(.conclusion)"' | grep -q "test:completed"; do sleep 10; done
gh run view $id --json jobs --jq '.jobs[] | "\(.name):\(.conclusion)"' | head -1
gh run view $id --log-failed 2>/dev/null | grep -E " error |Expected:|Actual:|Which:|FAILED|Test failed|══╡|\[E\]" | head -40
