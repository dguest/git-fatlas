# scripts to find packages in a repo

# _______________________________________________________________________
# init function
#
# This is the first thing you'll have to call to make a sparse
# checkout of Athena. By default this assumes you want to pull from
# the main athena repo and use release 21.2.
#
_git-fatlas-init_usage() {
    echo "usage: $1 [-h] [-r release] [-u URL]"
}
function git-fatlas-init() {
    (
        # set default configuration
        local RELEASE=21.2
        local URL=ssh://git@gitlab.cern.ch:7999/atlas/athena.git

        # parse options
        local opt
        while getopts ":hr:u:" opt $@; do
            case $opt in
                h) _git-fatlas-init_usage $FUNCNAME;
                   cat <<EOF

Sparse checkout atlas repo and switch to a branch. Note that after
you've run this you need to use git-fatlas-add to add some packages.

default release: $RELEASE
default repo: $URL

EOF
                   return 1;;
                r) RELEASE=${OPTARG} ;;
                u) URL=${OPTARG} ;;
                # handle errors
                \?) _git-fatlas-init_usage $FUNCNAME;
                    echo "Unknown option: -$OPTARG" >&2;
                    return 1;;
                :) _git-fatlas-init_usage $FUNCNAME;
                   echo "Missing argument for -$OPTARG" >&2;
                   return 1;;
                *) _git-fatlas-init_usage $FUNCNAME;
                   echo "Unimplemented option: -$OPTARG" >&2;
                   return 1;;
            esac
        done

        # clone a release without checking out any files
        git clone --no-checkout $URL

        # set up the sparse checkout, then move to the desired
        # branch. Note that this leaves git in a rather ugly position
        # since there are no packages checked out.
        cd athena
        git config core.sparsecheckout true
        touch .git/info/sparse-checkout
        git reset --soft origin/${RELEASE}
    )
}


# ______________________________________________________________________
# Remake package list
#
# We cache the package list in a local file to make tab-complete
# snappy. This could probably be further optimized (i.e. check the
# release and remove packages that aren't used, rebuild automatically
# when it goes out of date).
#
function git-fatlas-make-package-list() {
    git ls-tree --name-only -r HEAD | grep CMakeLists.txt\
        | sed 's@/CMakeLists.txt@@' | sort -f > ${1}
}
function git-fatlas-get-package-list() {
    local pkg_list_dir=/tmp/${USER-fatlas}/${PWD#/}
    mkdir -p $pkg_list_dir
    local pkg_list=${pkg_list_dir}/pkg_list
    if [[ ! -f $pkg_list ]]; then
        git-fatlas-make-package-list $pkg_list
    fi
    echo $pkg_list
}
function git-fatlas-remake-package-list() {
    # TODO, merge this with the above function
    local pkg_list_dir=/tmp/${USER-fatlas}/${PWD#/}
    mkdir -p $pkg_list_dir
    local pkg_list=${pkg_list_dir}/pkg_list
    git-fatlas-make-package-list $pkg_list
}

# ______________________________________________________________________
# Add package
#
# Should be pretty self-explanatory: adds the packages you ask for to
# the working tree. There are also tab complete functions defined
# below.
#
function git-fatlas-add() {
    local pkg_list=$(git-fatlas-get-package-list)
    local SP=.git/info/sparse-checkout
    local STUB
    local FULLPATH
    for STUB in ${@:1} ; do
        egrep "(^|/)${STUB%/}(/|$)" $pkg_list | while read FULLPATH; do
            echo ${FULLPATH%/}/ | tee -a $SP
        done
    done
    git checkout HEAD
}


# ____________________________________________________________________
# Remove package
#
# This one is a bit tricky in that we have to make sure we don't
# remove the last package. Git doesn't like that for some reason.
#
function git-fatlas-remove() {
    local SP=.git/info/sparse-checkout
    local TMP=$(cat $SP | sort -u | egrep -v $1)
    if [[ ${TMP} == '' ]]; then
        echo "ERROR: can't remove last package" 1>&2
        return 1
    fi
    local FILE
    rm $SP
    for FILE in $TMP; do
        echo $FILE >> $SP
    done
    git checkout HEAD
}


# ____________________________________________________________________
# Tab complete function for the add utility
#
function _git-fatlas-add() {

    # build or get package list
    local pkg_list=$(git-fatlas-get-package-list)

    # first check for completion from the root up
    COMPREPLY=( $(compgen -W "$(cat $pkg_list)" -- $2 ) )
    if [[ ${#COMPREPLY[*]} != 0 ]]; then
        return 0
    fi

    # then check for a unique fgrep match
    COMPREPLY=( $(fgrep ${2} $pkg_list ) )
    if [[ ${#COMPREPLY[*]} == 1 ]]; then
        return 0
    fi

    # then check to see if any part of the package name matches note
    # that we can't include the full path because that will trigger a
    # completion to any stub that is shared among all matches.
    COMPREPLY=( $(fgrep ${2} $pkg_list | egrep -o "[^/]*$2.*") )
    return 0
}
complete -F _git-fatlas-add git-fatlas-add
