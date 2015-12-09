#!/bin/bash
# Repository mirrorer
# © John Peterson. License GNU GPL 3.

function create_repo() {
	name=$1
	description=$2

	# create repo
	json=$(curl -s -u "$user:$pwd" -d "{\"name\":\"$name\"}" https://api.github.com/orgs/$org/repos)
	error=$(echo "$json" | jshon -Q -e message -u)
	if [ -n "$error" ]; then
		echo $error;
		return 1
	fi

	# set description
	json=$(curl -s -u "$user:$pwd" -X PATCH -d "{\"name\":\"$name\", \"description\":\"$description\"}" https://api.github.com/repos/$org/$name)
}

function git_mirror() {
	# vars
	TO=(${1//\// });
	to=${TO[0]}
	branch=${TO[1]}
	type=$2
	from=$3
	arg=$4
	dir=$REPO_HOME/$to

	# exceptions
	if [ -z "$REPO_HOME" ]; then echo "REPO_HOME not set"; return 1; fi
	if [ ! -d "$REPO_HOME" ]; then echo "$REPO_HOME doesn't exist"; return 1; fi

	# create boolean
	isbzr=`if [[ "$type" =~ "bzr" ]]; then printf true; else printf false; fi`
	isgit=`if [[ "$type" =~ "git" ]]; then printf true; else printf false; fi`
	issvn=`if [[ "$type" =~ "svn" ]]; then printf true; else printf false; fi`

	# create repo
	json=$(curl -s https://api.github.com/repos/$org/$to)
	error=$(echo "$json" | jshon -Q -e message -u)
	if [ -n "$error" ] && [[ "$error" != "API rate limit exceeded"* ]]; then
		echo $error;
		if ! create_repo $to "$from $arg"; then
			return 1
		fi
	fi

	# push command
	if [ -n "$branch" ]; then
		dir=${dir}_$branch
		m="push origin HEAD:$branch"
	else
		if $isbzr; then
			m="push --tags origin HEAD:master"
		elif $issvn; then
			m="push"
		else
			m="push --mirror"
		fi
	fi

	# log
	echo ►$to $(date -Is)

	# pull command
	case "$type" in
	bzr) c="bzr clone $from ."
		p='bzr sync bzr/master';;
	cvs) c="cvsimport -i -d $from $arg"
		p="$c";;
	git) c="clone --mirror $from ."
		p='remote update';;
	hg) c="hg clone $from ."
		p='hg pull';;
	svn) c="svn clone $arg $from ."
		p="svn rebase";;
	*) echo "$type is unsupported"; return 1;;
	esac

	if $isgit; then
		r='set-url --push'
	else
		r='add'
	fi

	# clone
	if [[ ! -d $dir || ! ($isgit && -f $dir/HEAD || !$isgit && -f $dir/.git/HEAD) ]]; then
		mkdir -p $dir; pushd $dir
		echo $ git $c
		git $c
		echo $ git remote $r origin git@github.com:$org/$to.git
		git remote $r origin git@github.com:$org/$to.git

		# select branch
		if $isbzr; then
			echo $ git checkout bzr/master
			git checkout bzr/master
		fi
	fi

	# change directory
	pushd $dir

	# sync
	echo $ git $p
	git $p
	echo $ git $m
	git $m

	popd
}
