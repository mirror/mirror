#!/bin/bash
# Repository mirrorer
# © John Peterson. License GNU GPL 3.

function show_usage() {
	echo mirror repo to git hub
	echo example usage: "git_mirror.sh abc bzr http://launchpad/abc "" --debug --dry-run"
	exit 0
}

if [ $# -lt 3 ]; then
	echo too few arguments
	show_usage
	exit 1
fi

# defaults
isdry=false
isdebug=false

# while [ $# -ge 1 ]; do
for var in "$@"; do
case "$var" in
	-\?|-h|--help|--usage)
		show_usage;;
	-n|--dry-run)
		isdry=true;;
	-d|--debug)
		isdebug=true;;
esac
done

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

# function git_mirror() {
	# vars
	TO=(${1//\// });
	to=${TO[0]}
	branch=${TO[1]}
	type=$2
	from=$3
	arg=$4

	# repo home
	if [ -z "$REPO_HOME" ]; then echo "REPO_HOME not set using ."; REPO_HOME=.; fi
	if [ ! -d "$REPO_HOME" ]; then echo "$REPO_HOME doesn't exist"; return 1; fi
	dir=$REPO_HOME/$to

# target org
if [ -z "$org" ]; then
	echo org is unset using mirror
	org=mirror
fi

	# create boolean
	isbzr=`if [[ "$type" =~ "bzr" ]]; then printf true; else printf false; fi`
	isgit=`if [[ "$type" =~ "git" ]]; then printf true; else printf false; fi`
	issvn=`if [[ "$type" =~ "svn" ]]; then printf true; else printf false; fi`


# debug
if $isdebug; then
	echo to $to
	echo branch $branch
	echo type $type
	echo from $from
	echo arg $arg
	set -x
fi

# disable all commands
if $isdry; then
	shopt -s expand_aliases
	for a in bzr curl git hg jshon mkdir popd pushd svn; do
		alias $a="echo $a"
	done
	type git
	git -v
fi

# create repo if git_login is sourced
if [ -n "$user" ]; then
	json=$(curl -s https://api.github.com/repos/$org/$to)
	error=$(echo "$json" | jshon -Q -e message -u)
	if [ -n "$error" ] && [[ "$error" != "API rate limit exceeded"* ]]; then
		echo $error;
		if ! create_repo $to "$from $arg"; then
			return 1
		fi
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
	echo pushing $to $(date -Is)

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
	git $c
	git remote $r origin git@github.com:$org/$to.git
fi

	# select branch
	if $isbzr; then
		git checkout bzr/master
	fi

	# change directory
	pushd $dir

	# sync
	git $p
	git $m

	# return to home
	popd

	if $isdebug; then set +x; fi
# }
