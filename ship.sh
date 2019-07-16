# ships `public/`
# based on https://gist.github.com/cobyism/4730490
set -ex

# make sure everything we care about has already been 
# pushed upstream 
git push origin the-details

# removes the master branch, and splits the subtree
# into it.
git branch -D master
git subtree split --prefix public -b master

# we do this dance because the master
# branch would have changed with the cname
# things from having the site up on github
# pages, and... we don't really want to squash
# that CNAME
git checkout master
git pull origin master --rebase
git push origin master

# go back to our working branch
git checkout the-details
