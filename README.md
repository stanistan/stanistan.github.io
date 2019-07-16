# stanistan

Personal website. Powered by [zola](https://getzola.org).

Should be edited from the `the-details` branch.

```sh
# Do changes... 

# build the site 
zola build

# commit the generated changes
git add ...
git commit 

# push upstream
git push origin the-details

# push the changes to master...
# master is where/how the site actually works,
# powering stanistan.github.io -> www.stanistan.com
git branch -D master
git subtree split --prefix public -b master
git checkout master
git pull origin master --rebase
git push origin master
git checkout the-details

# or ./ship.sh
```
