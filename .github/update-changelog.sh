#!/bin/bash

string=`git config --get remote.origin.url`
prefix="git@github.com:"
suffix=".git"
repo=${string#$prefix}
repo=${repo%$suffix}
git checkout -b changelog_update
github_changelog_generator
git add CHANGELOG.md
git commit -m "changelog update [ci skip]"
git remote add changelog https://${CHANGELOG_GITHUB_TOKEN}@github.com/${repo}.git
git push -u changelog changelog_update
url=$(curl -v -d '{"title":"Changelog Update [ci skip]","head":"changelog_update","base":"master"}' -H "Content-Type: application/json" -H "Authorization: token ${CHANGELOG_GITHUB_TOKEN}" https://api.github.com/repos/${repo}/pulls | jq '.url')
echo $url
if [ -z ${url+x} ]; then
  echo 'Error on creating pull request'
else
  url=${url#\"}
  url=${url%\"}
  sha=$(curl -v -H "Content-Type: application/json" -H "Authorization: token ${CHANGELOG_GITHUB_TOKEN}" -X PUT ${url}/merge | jq '.merged')
  if [ -z ${sha+x} ]; then
    echo 'Error on merging'
  else
    curl -v -H "Content-Type: application/json" -H "Authorization: token ${CHANGELOG_GITHUB_TOKEN}" -X DELETE https://api.github.com/repos/${repo}/git/refs/heads/changelog_update
    url_develop=$(curl -v -d '{"title":"Update Develop [ci skip]","head":"master","base":"develop"}' -H "Content-Type: application/json" -H "Authorization: token ${CHANGELOG_GITHUB_TOKEN}" https://api.github.com/repos/${repo}/pulls | jq '.url')
    if [ -z ${url+x} ]; then
      echo 'Error on creating pull request on develop'
    else
      url_develop=${url_develop#\"}
      url_develop=${url_develop%\"}
      curl -v -H "Content-Type: application/json" -H "Authorization: token ${CHANGELOG_GITHUB_TOKEN}" -X PUT ${url_develop}/merge
    fi
  fi
fi