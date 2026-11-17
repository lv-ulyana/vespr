#!/bin/bash
# Швидка перевірка без деплою: коміт → пуш у гілку wip → чекаємо workflow quick → друкуємо помилки.
# Повна збірка з деплоєм — tool/ci.sh (пуш у main).
cd "$(dirname "$0")/.."
if [ -n "$(git status --porcelain)" ]; then
  git add -A && git -c user.name="Claude" -c user.email="noreply@anthropic.com" commit -qm "${1:-wip}

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_014gfNJfnkC9T8fbke2Fq96Y"
fi
sha=$(git rev-parse HEAD)
git push -q -f origin HEAD:wip
for i in $(seq 1 30); do
  id=$(gh run list -L5 --workflow quick.yml --json databaseId,headSha --jq ".[] | select(.headSha==\"$sha\") | .databaseId" | head -1)
  [ -n "$id" ] && break; sleep 5
done
until [ "$(gh run view $id --json status --jq .status)" = completed ]; do sleep 10; done
echo "quick: $(gh run view $id --json conclusion --jq .conclusion)"
gh run view $id --log 2>/dev/null | sed 's/^[^\t]*\t[^\t]*\t[^ ]* //' | grep -E " error •|ПРОБЛЕМИ|^[a-z_]+/[a-z_0-9]+:|^== build|^[a-zA-Z]+: .*[А-Яа-яІіЇїЄє]|Some tests failed|All tests passed|tests passed|\[E\]" | head -80
