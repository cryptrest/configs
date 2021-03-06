#!/bin/sh

CURRENT_DIR="$(cd $(dirname "$0") && pwd -P)"

CRYPTREST_ENV_FILE="$CURRENT_DIR/../.env"
CRYPTREST_MODULES_DIR="$CURRENT_DIR/../modules"
if [ ! -f "$CRYPTREST_ENV_FILE" ]; then
    CRYPTREST_ENV_FILE="$CURRENT_DIR/../../../.env"
fi
if [ ! -d "$CRYPTREST_MODULES_DIR" ]; then
    CRYPTREST_MODULES_DIR="$(readlink "$0")"

    if [ -z "$CRYPTREST_MODULES_DIR" ]; then
        CRYPTREST_MODULES_DIR="$(dirname "$0")"
    else
        CRYPTREST_MODULES_DIR="$(dirname "$CRYPTREST_MODULES_DIR")"
    fi
    CRYPTREST_MODULES_DIR="$CRYPTREST_MODULES_DIR/../modules"
fi

echo ''
printf 'CryptREST config file: '
if [ -f "$CRYPTREST_ENV_FILE" ]; then
    . "$CRYPTREST_ENV_FILE"

    echo 'loaded'
else
    echo 'not loaded'
fi


CURRENT_DIR="$(cd $(dirname "$0") && pwd -P)"

# CRYPTREST_MODULES='go nginx openssl letsencrypt'
CRYPTREST_MODULES="${CRYPTREST_MODULES:=}"
CRYPTREST_INSTALLER_GIT_BRANCH="${CRYPTREST_INSTALLER_GIT_BRANCH:=master}"

CRYPTREST_NAME='cryptrest'
CRYPTREST_TITLE='CryptREST Modules'
CRYPTREST_INSTALLER_GIT_URL="https://github.com/$CRYPTREST_NAME/installer/archive/$CRYPTREST_INSTALLER_GIT_BRANCH.tar.gz"
CRYPTREST_USER="$USER"
CRYPTREST_DIR="$HOME/.$CRYPTREST_NAME"
CRYPTREST_ENV_FILE="$CRYPTREST_DIR/.env"
CRYPTREST_LIB_DIR="$CRYPTREST_DIR/lib"
CRYPTREST_OPT_DIR="$CRYPTREST_DIR/opt"
CRYPTREST_BIN_DIR="$CRYPTREST_DIR/bin"
CRYPTREST_SRC_DIR="$CRYPTREST_DIR/src"
CRYPTREST_ETC_DIR="$CRYPTREST_DIR/etc"
CRYPTREST_WWW_DIR="$CRYPTREST_DIR/www"
CRYPTREST_VAR_DIR="$CRYPTREST_DIR/var"
CRYPTREST_VAR_LOG_DIR="$CRYPTREST_VAR_DIR/log"
CRYPTREST_ETC_SSL_DIR="$CRYPTREST_ETC_DIR/ssl"
CRYPTREST_TMP_DIR="${TMPDIR:=/tmp}/$CRYPTREST_NAME"
CRYPTREST_MUDULES_LIB_BIN_DIR="$CRYPTREST_LIB_DIR/installer-$CRYPTREST_INSTALLER_GIT_BRANCH/bin"
CRYPTREST_INSTALLER_LIB_VERSION_FILE="$CRYPTREST_MUDULES_LIB_BIN_DIR/../VERSION"
CRYPTREST_MUDULES_LIB_BIN_FILE="$CRYPTREST_MUDULES_LIB_BIN_DIR/modules.sh"

CRYPTREST_MODULES_ALL='all'
CRYPTREST_MODULES_DEFAULT='go'
CRYPTREST_MODULES_ARGS="$*"
CRYPTREST_IS_LOCAL=1


cryptrest_init()
{
    mkdir -p "$CRYPTREST_OPT_DIR" && \
    chmod 700 "$CRYPTREST_OPT_DIR" && \
    mkdir -p "$CRYPTREST_SRC_DIR" && \
    chmod 700 "$CRYPTREST_SRC_DIR" && \
    mkdir -p "$CRYPTREST_BIN_DIR" && \
    chmod 700 "$CRYPTREST_BIN_DIR" && \
    mkdir -p "$CRYPTREST_TMP_DIR" && \
    chmod 700 "$CRYPTREST_TMP_DIR" && \
    mkdir -p "$CRYPTREST_LIB_DIR" && \
    chmod 700 "$CRYPTREST_LIB_DIR" && \
    mkdir -p "$CRYPTREST_ETC_DIR" && \
    chmod 700 "$CRYPTREST_ETC_DIR" && \
    mkdir -p "$CRYPTREST_ETC_SSL_DIR" && \
    chmod 700 "$CRYPTREST_ETC_SSL_DIR" && \
    mkdir -p "$CRYPTREST_VAR_DIR" && \
    chmod 700 "$CRYPTREST_VAR_DIR" && \
    mkdir -p "$CRYPTREST_VAR_LOG_DIR" && \
    chmod 700 "$CRYPTREST_VAR_LOG_DIR" && \
    mkdir -p "$CRYPTREST_MUDULES_LIB_BIN_DIR" && \
    chmod 700 "$CRYPTREST_MUDULES_LIB_BIN_DIR" && \

    echo "$CRYPTREST_TITLE structure: check"
}

cryptrest_modules()
{
    local modules=''

    [ -z "$CRYPTREST_MODULES_ARGS" ] && \
    [ -z "$CRYPTREST_MODULES" ] && \
    CRYPTREST_MODULES_ARGS="$CRYPTREST_MODULES_DEFAULT"

    if [ -z "$CRYPTREST_MODULES_ARGS" ]; then
        modules="$CRYPTREST_MODULES"
    else
        modules="$CRYPTREST_MODULES_ARGS"
    fi

    [ "$modules" = "$CRYPTREST_MODULES_ALL" ] && modules="$(ls "$CRYPTREST_MODULES_DIR")"

    CRYPTREST_MODULES=''

    for m in $modules; do
        if [ -d "$CRYPTREST_MODULES_DIR/$m" ] && [ -f "$CRYPTREST_MODULES_DIR/$m/install.sh" ]; then
            CRYPTREST_MODULES="$CRYPTREST_MODULES $m"
        else
            echo "$CRYPTREST_TITLE WARNING: module '$m' does not exist"
        fi
    done
}

cryptrest_is_local()
{
    if [ -d "$CRYPTREST_MODULES_DIR/" ]; then
        for m in $(ls "$CRYPTREST_MODULES_DIR"); do
            if [ -d "$CRYPTREST_MODULES_DIR/$m" ] && [ -f "$CRYPTREST_MODULES_DIR/$m/install.sh" ]; then
                CRYPTREST_IS_LOCAL=0

                break
            fi
        done
    fi

    return $CRYPTREST_IS_LOCAL
}

cryptrest_local_install()
{
    echo "$CRYPTREST_TITLE mode: local"
    echo ''

    for m in $(echo "$CRYPTREST_MODULES" | sort); do
        . "$CRYPTREST_MODULES_DIR/$m/install.sh"
        [ $? -ne 0 ] && return 1
    done

    return 0
}

cryptrest_download()
{
    cd "$CRYPTREST_LIB_DIR" && \
    curl -SL "$CRYPTREST_INSTALLER_GIT_URL" | tar -xz
    if [ $? -ne 0 ]; then
        echo "$CRYPTREST_TITLE: Some errors with download"
        rm -rf "$CRYPTREST_MUDULES_LIB_BIN_DIR"

        exit 1
    fi
}

cryptrest_network_install()
{
    echo "$CRYPTREST_TITLE mode: network"
    echo ''

    cryptrest_download && \
    CRYPTREST_MODULES="$CRYPTREST_MODULES" "$CRYPTREST_MODULES_LIB_BIN_FILE" $CRYPTREST_MODULES_ARGS
}

cryptrest_version_define()
{
    local version=''
    local message=''

    if [ -f "$CRYPTREST_INSTALLER_LIB_VERSION_FILE" ]; then
        version="$(cat "$CRYPTREST_INSTALLER_LIB_VERSION_FILE")"
        message=" (version: $version)"
    fi

    echo "$message"
}

cryptrest_define()
{
    if [ $? -eq 0 ]; then
        echo ''
        echo "$CRYPTREST_TITLE$(cryptrest_version_define): installation successfully completed!"
        echo ''
    fi
}

cryptrest_install()
{
    local status=0
    local modules_bin_dir=''

    cryptrest_is_local
    if [ $? -eq 0 ]; then
        cryptrest_local_install
        if [ $? -eq 0 ]; then
            status=0
            modules_bin_dir="$(cd "$CRYPTREST_MODULES_DIR/../bin" && pwd -P)"

            if [ "$modules_bin_dir" != "$CRYPTREST_MUDULES_LIB_BIN_DIR" ]; then
                rm -f "$CRYPTREST_MUDULES_LIB_BIN_FILE" && \
                cp "$modules_bin_dir/modules.sh" "$CRYPTREST_MUDULES_LIB_BIN_FILE"
            fi

            chmod 500 "$CRYPTREST_MUDULES_LIB_BIN_FILE" && \
            status=$?
        else
            status=1
        fi
        [ $status -eq 0 ] && cryptrest_define
    else
        cryptrest_network_install
    fi
}


cryptrest_modules && \
cryptrest_init && \
cryptrest_install
