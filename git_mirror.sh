#!/bin/bash
# Repository mirrorer
# © John Peterson. License GNU GPL 3.

# import
source git_login.sh 2>/dev/null

function show_usage() {
	echo mirror repo to git hub
	echo 'example usage: git_mirror.sh abc bzr http://launchpad/abc "" --debug --dry-run
--fast skip svn cvs
--interactive require user input
--resume experiment to resume existing svn cvs mirror
--small less 100 meg
--type=hg only this type
'
	exit 0
}

if [ $# -lt 3 ]; then
	echo too few arguments
	show_usage
	exit 1
fi

# defaults
isbzr=false
iscvs=false
isgit=false
issvn=false
isdebug=false
isdry=false
isfast=false
isint=false
isresume=false
issmall=false
istest=false

for arg in "$@"; do
case "$arg" in
	-\?|-h|--help|--usage)
		show_usage;;
	-d|--debug)
		isdebug=true;;
	-n|--dry-run)
		isdry=true;;
	-f|--fast)
		isfast=true;;
	-i|--interactive)
		isint=true;;
	-r|--resume)
		isresume=true;;
	-s|--small)
		issmall=true;;
	-t|--test)
		istest=true;;
	-y=*|--type*)
		istype=$(echo $arg|cut -f2 -d=);;
esac
done

# disable all commands
if $isdry; then
	shopt -s expand_aliases
	for a in bzr git hg mkdir popd pushd rm svn; do
		alias $a="echo $a"
	done
	# type git; git -v
fi

function format() {
	if $1; then
		local bold=$(tput bold)
	fi
	if [ $2 -gt -1 ]; then
		local color=$(tput setaf $2)
	fi
	normal=$(tput sgr0)
	shift 2
	echo "${bold}${color}$@${normal}"
}

# cloud machine are rate limited 
function have_api() {
	if $isdry; then
		eval $1=false
		return
	fi
	json=$(curl -s https://api.github.com/repos/$org/$to)
	error=$(echo $json | jshon -Q -e message -u)
	if [[ "$error" = "API rate limit exceeded"* ]]; then	
	# if [[ -n "$error" ]]; then	
	# if true; then	
		# echo error $error;
		if [ -z "$user" ]; then
			echo user unset API unavailable
		else
			# retry with credentials 
			json=$(curl -s -u "$user:$pwd" https://api.github.com/repos/$org/$to)
			error=$(echo $json | jshon -Q -e message -u)
			if [ -z "$error" ]; then
				eval $1=true
				login="-u $user:$pwd"
			else
				# echo error $error
			echo API unavailable
			fi
		fi
	else
		eval $1=true
	fi
}

function is_big() {
	if ! ($isfast || $issmall); then return 0; fi
	echo checking size
	if $isdry; then	return 0; fi
	if ! $haveapi; then	return 0; fi
	json=$(curl -s $login https://api.github.com/repos/$org/$to)
	size=$(echo $json|jshon -e size -u)
	megs=$(numfmt --to=iec $(($size*1024)))
if [ $size -gt 100000 ]; then
	format false 9 $megs too big for --fast and --small
	exit 1
else
	format false 2 $megs
fi
}

# only git has shallow clones
function is_behind() {
	if ! $haveapi || $isdry || ! $isgit; then	return 0; fi
	echo comparing head dates

	case "$type" in
	git)
		local c="clone --quiet --depth=1";;
	hg)
		local c=" hg clone";;
	*) format false 9 add $type date comparison
		return 0;;
	esac

	# shopt -u expand_aliases
	rm -rf tmp
	mkdir tmp
	pushd tmp
	echo cloning $from ...
	git $c $from .
	sd=$(TZ=UTC0 git show HEAD --quiet --date=iso-strict-local --format="%cd"|sed "s,+00:00,Z,")
	popd
	# shopt -s expand_aliases
	
	json=$(curl -s $login https://api.github.com/repos/$org/$to/branches/master)
	md=$(echo $json|jq -r '.. | .date? | strings'|tail -1)

	if [ "$sd" == "$md" ]; then
		format false 2 up to date $sd
		exit 0
	else
		format false 9 updating from $md to $sd
	fi
}

function mirror_exist() {
	if ! $haveapi || $isdry; then	return 0; fi
	echo check for existing repo
	json=$(curl -s $login https://api.github.com/repos/$org/$to)
	error=$(echo $json | jshon -Q -e message -u)
	if [[ "$error" = "Not Found" ]]; then
		format false 10 new mirror $org/$to;
		return 1
	else
		echo $org/$to exist
		return 0
	fi
}

# create empty repo
function create_repo() {
	description="$from $arg"

	if [ -z "$user" ]; then
		echo user unset
		return 1
	fi
	
	# create repo
	json=$(curl -s $login -d "{\"name\":\"$to\"}" https://api.github.com/orgs/$org/repos)
	error=$(echo "$json" | jshon -Q -e message -u)
	if [ -n "$error" ]; then
		echo $error;
		return 1
	fi

	# set description
	json=$(curl -s $login -X PATCH -d "{\"name\":\"$name\", \"description\":\"$description\"}" https://api.github.com/repos/$org/$name)
}

	# args
	TO=(${1//\// });
	to=${TO[0]}
	branch=${TO[1]}
	type=$2
	from=$3
arg=$4

	# repo home
	if [ -z "$REPO_HOME" ]; then
		# echo "REPO_HOME not set using ."
		REPO_HOME=.
	fi
	if [ ! -d "$REPO_HOME" ]; then echo "$REPO_HOME doesn't exist"; return 1; fi
	dir=$REPO_HOME/$to

# target org
if [ -z "$org" ]; then
	# echo org is unset using mirror
	org=mirror
fi

	# type
	m="push -q --mirror"
	r='add'
	case "$type" in
	bzr) isbzr=true
		c="bzr clone $from ."
		p='bzr sync bzr/master'
		m="push --tags origin HEAD:master";;
	cvs) iscvs=true
		c="cvsimport -i -d $from $arg"
		p="$c";;
	git) isgit=true
		c="clone -q --mirror $from ."
		p='remote update'
		s=set-url
		r='set-url --push';;
	hg) c="clone --mirror hg::$from ."
		p="pull"
		r='set-url --push';;
		# git-hg is broken "Cannot chdir to $cdup..."
		# c="hg clone $from ."
		# p='hg pull';;
	svn) issvn=true
		git config --global http.sslVerify false
		c="svn -qq clone $arg $from ."
		p="svn -qq rebase"
			m="push origin master";;
	*) echo "$type is unsupported"; return 1;;
	esac
	
	# title
	echo
	format true -1 $to $type

# debug
if $isdebug; then
	set -x
fi

	# skip type

if [ -n "$istype" -a "$istype" != "$type" ]; then
	exit
fi

	# branch push command
	if [ -n "$branch" ]; then
		dir=${dir}_$branch
		m="push origin HEAD:$branch"
	fi

if $isint; then
read -s -n 1 -p "mirror [␣↵/*]" yn
echo
case $yn in
"" ) ;;
* ) exit;;
esac
fi

# clone
# why do we need this?
# isrepo=($isgit && -f $dir/HEAD || !$isgit && -f $dir/.git/HEAD)
if [[ -d $dir ]]; then
	echo resume existing repo
	pushd $dir
	git $p

else
echo no existing clone on disk

	if $isfast && [ -z "$istype" ] && ($issvn || $iscvs); then
		echo --fast disable new $type clones
		exit 1
	fi

	if $isresume && ! $isgit; then
		echo $type not support resume
		exit 1
	fi

# api
haveapi=false
have_api haveapi

# test
if $istest; then
	is_big
	# is_behind
	# mirror_exist
	exit
fi
	is_big

	is_behind

	echo creating new folder $to
	mkdir -p $dir
	pushd $dir

	if ! mirror_exist; then
		echo create new repo
		if ! create_repo; then
			exit 1
		fi
	fi

	# this produce errors related to pull requests refs/pull/1/head
	# if $isresume && $isgit; then
	if false; then
		echo clone existing mirror 
		git clone --mirror git@github.com:$org/$to .
		echo update remote
		git remote $s origin $from
		git remote $r origin git@github.com:$org/$to

	else
		echo $(date -Im -u)Z cloning $from ...
		git $c
		echo update remote address
		git remote $r origin git@github.com:$org/$to
	fi
fi

	# select branch - fix this
	if $isbzr; then
		git checkout bzr/master
	fi

	# sync
	echo updating $org/$to ...
	git $m
res=$?

	# return home
	popd

if [ $res -eq 0 ]; then
	format true 2 success
	# keep big and slow repos 
	if $isfast && $isgit; then
		rm -rf $dir
	fi
else
	format true 9 fail
fi

if $isdebug; then set +x; fi
