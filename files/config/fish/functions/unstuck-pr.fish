function unstuck-pr --argument args
  git fetch
  gh pr checkout $args
  git commit --amend --no-edit --allow-empty
  git push --force
end
