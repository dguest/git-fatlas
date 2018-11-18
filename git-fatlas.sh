# scripts to find packages in a repo

_git-fatlas-init_usage() {
    echo "usage: $1 [-h] [-r release] [-u URL]"
}
function git-fatlas-init() {
    (
        local RELEASE=21.2
        local URL=ssh://git@gitlab.cern.ch:7999/atlas/athena.git

        local opt
        while getopts ":hr:u:" opt $@; do
            case $opt in
                h) _git-fatlas-init_usage $FUNCNAME;
                   cat <<EOF

Sparse checkout atlas repo and switch to a branch

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

        git clone --no-checkout $URL
        cd athena
        git config core.sparsecheckout true
        touch .git/info/sparse-checkout
        git reset --soft origin/${RELEASE}
    )
}


function git-fatlas-remake-package-list() {
    git ls-tree --name-only -r HEAD | grep CMakeLists.txt\
        | sed 's@/CMakeLists.txt@@' | sort -f > ${1-.pkg_list}
}

function git-fatlas-add() {
    local SP=.git/info/sparse-checkout
    local FILE
    for FILE in ${@:1} ; do
        echo ${FILE%/}/ >> $SP
    done
    git checkout HEAD
}

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

# TODO: add tab complete for remove?

function _git-fatlas-add() {
    local pkg_list_dir=/tmp/${USER}/${PWD}
    mkdir -p $pkg_list_dir
    local pkg_list=${pkg_list_dir}/pkg_list
    if [[ ! -f $pkg_list ]]; then
        git-fatlas-remake-package-list $pkg_list
    fi

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
