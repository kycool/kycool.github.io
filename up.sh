#!/usr/bin/env bash

BASE_DIR=/Users/allenwork/Music/blogshow

# git add --all && git commit -m "update" && git push -u origin main

echo "🔥：更新文件: $BASE_DIR"

# Check if there are changes to be committed
if git status | grep -q "nothing to commit, working tree clean"; then
  echo "    无文件要提交，干净的工作区"
else
  git add --all
  git commit -m "update blog"
  git push -u origin main
fi
echo "--------------------------------------------"
