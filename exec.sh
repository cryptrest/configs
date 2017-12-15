#!/bin/sh

CURRENT_DIR="$(cd $(dirname $0) && pwd -P)"

CRYPTREST_DIR="$HOME/.cryptrest"
CRYPTREST_INSTALLER_DIR="$CRYPTREST_DIR/installer"
CRYPTREST_INSTALLER_PATH="$HOME/installer"
CRYPTREST_BRANCH='master'
CRYPTREST_GIT_URL="https://github.com/cryptrest/installer/archive/$CRYPTREST_BRANCH.tar.gz"
CRYPTREST_MODULES='go letsencrypt nginx'
CRYPTREST_IS_LOCAL=1


cryptrest_is_local()
{
    for i in $CRYPTREST_MODULES; do
        if [ -d "$CURRENT_DIR/$i" ] && [ -f "$CURRENT_DIR/$i/install.sh" ]; then
            CRYPTREST_IS_LOCAL=0
            break
        fi
    done

    return $CRYPTREST_IS_LOCAL
}

cryptrest_local()
{
    echo ''
    echo 'Crypt REST mode: local'
    echo ''

    for i in $CRYPTREST_MODULES; do
        "$CURRENT_DIR/$i/install.sh"
    done
}

cryptrest_download()
{
    mkdir -p "$CRYPTREST_DIR" && \
    cd "$CRYPTREST_DIR" && \
    curl -SL "$CRYPTREST_GIT_URL" | tar -xz
    if [ $? -ne 0 ]; then
        echo "Some error with download"
        rm -rf "$CRYPTREST_DIR"

        exit 1
    fi
}

cryptrest_network()
{
    echo ''
    echo 'Crypt REST mode: network'
    echo ''

    rm -rf "$CRYPTREST_DIR" && \
    cryptrest_download && \
    mv -f "$CRYPTREST_INSTALLER_DIR-$CRYPTREST_BRANCH" "$CRYPTREST_INSTALLER_DIR" && \
    chmod 700 "$CRYPTREST_DIR"
    if [ $? -eq 0 ]; then
        "$CRYPTREST_INSTALLER_DIR/exec.sh"
    fi
}

cryptrest_install()
{
    cryptrest_is_local
    if [ $? -eq 0 ]; then
        cryptrest_local && \
        rm -rf "$CRYPTREST_INSTALLER_PATH" && \
        mkdir -p "$CRYPTREST_INSTALLER_PATH" && \
        ln -s "$CURRENT_DIR/exec.sh" "$CRYPTREST_INSTALLER_PATH/index.html"
    else
        cryptrest_network && \
        rm -rf "$CRYPTREST_INSTALLER_PATH" && \
        mkdir -p "$CRYPTREST_INSTALLER_PATH" && \
        ln -s "$CRYPTREST_INSTALLER_DIR/exec.sh" "$CRYPTREST_INSTALLER_PATH/index.html"
    fi
}


cryptrest_install