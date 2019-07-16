set -ex
# ships `public/`
# based on https://gist.github.com/cobyism/4730490
git branch -D master
git subtree split --prefix public -b master
git checkout master
git pull origin master --rebase
git push origin master
git checkout the-details
