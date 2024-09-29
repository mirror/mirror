
This repo is a meta-repository for housing all issues and tooling related to the administration
of the mirror org and its repositories.

# usage

to mirror a svn source forge repo to abc/123

~~~
export org=abc
export REPO_HOME=~/repos
mkdir -p $REPO_HOME
bash git_mirror.sh 123 svn https://svn.code.sf.net/p/123/code/trunk --dry-run
~~~

to update all small bzr mirrors hosted here 

~~~
bash mirror.sh --type=bzr --interactive --small --dry-run
~~~


# unable to pull --  history lost upstream

we are working on a patch that will resume svn cvs mirrors

https://github.com/mirror/mirror/discussions

until then sometimes svn cvs mirrors rewrite the history from scratch. when this happens

store all your changes

~~~
git format-patch -3
git stash
git checkout -b oldmaster
~~~

delete and download again

~~~
git checkout HEAD~99
git branch -d master
git fetch
git checkout origin master
~~~

# Index

| Repo Name | Mirror URL | Upstream URL |
|-----------|------------|--------------|
| TODO      | TODO       | TODO         |

# About

Mirror is dedicated to hosting unofficial Git mirrors of various popular opens-source
repositories that are scattered across the internet. It arose from my need to host and publish my patches. 

# Contributing

There are various ways one can contribute. 

## Requesting a new repository mirror

Before you request that a repository be mirrored, please take a look through our repositories to 
make sure that the repository you are looking for isn't already mirrored. 

Otherwise, open an issue in this repository and use the "Request to mirror a repo" template to
provide us with some details about the repository you'd like to see mirrored. Generally we 
can only mirror repositories that have licenses that allow for redistribution of the source
code. 

## Requesting an existing mirror be removed

There are only two cases when a mirror will be considered for removal:

1. If the upstream repo is no longer being maintained because it has moved either to GitHub or elsewhere
   and it no longer makes sense for us maintain a mirror. 
2. If there is a genuine legal concern regarding compliance with the license terms of the upstream 
   repository (e.g. not using a Free/Libre or Open Source license) that would affect our ability to legally redistribute
   the source code. 

If you believe that a mirror in this org meets one or both of the above cases, then please open
an issue in this repo and provide us with some more details about the circumstances. 

However, if there are no technical or legal grounds for the removal of the mirror, the issue 
will be closed without any further action taken. 

## Making contributions yourself

If you'd rather contribute directly to the project, please feel free to create a pull request. It is 
also highly recommended that you read the [CONTRIBUTING][CONTRIBUTING.md] docs for more detailed
information on making contributions to the org. 
