#!/usr/bin/env bash

# Define directories.
SCRIPT_DIR=$PWD
TOOLS_DIR=$SCRIPT_DIR/tools
CAKE_VERSION=0.24.0
CAKE_DLL=$TOOLS_DIR/Cake.$CAKE_VERSION/Cake.exe
DOTNET_VERSION=$(cat "$SCRIPT_DIR/global.json" | grep -o '[0-9]\.[0-9]\.[0-9][0-9][0-9]')
DOTNET_INSTRALL_URI=https://raw.githubusercontent.com/dotnet/cli/master/scripts/obtain/dotnet-install.sh

get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

echo $DOTNET_VERSION

# Make sure the tools folder exist.
if [ ! -d "$TOOLS_DIR" ]; then
  mkdir "$TOOLS_DIR"
fi

###########################################################################
# INSTALL .NET CORE CLI
###########################################################################

echo "Installing .NET CLI..."
if [ ! -d "$SCRIPT_DIR/.dotnet" ]; then
  mkdir "$SCRIPT_DIR/.dotnet"
fi
curl -Lsfo "$SCRIPT_DIR/.dotnet/dotnet-install.sh" $DOTNET_INSTRALL_URI
bash "$SCRIPT_DIR/.dotnet/dotnet-install.sh" -c current --version $DOTNET_VERSION --install-dir .dotnet --no-path
export PATH="$SCRIPT_DIR/.dotnet":$PATH
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
"$SCRIPT_DIR/.dotnet/dotnet" --info

if [ ! -d "$SCRIPT_DIR/.nuget" ]; then
  mkdir "$SCRIPT_DIR/.nuget"
fi
curl -Lsfo "$SCRIPT_DIR/.nuget/nuget.exe" https://dist.nuget.org/win-x86-commandline/latest/nuget.exe

###########################################################################
# INSTALL PAKET Dependecy resolver
###########################################################################

PAKET_VERSION=$( get_latest_release  "fsprojects/Paket" );
PAKET_BOOTSTRAPPER_URL=https://github.com/fsprojects/Paket/releases/download/$PAKET_VERSION/paket.bootstrapper.exe
PAKET_BOOTSTRAPPER="$SCRIPT_DIR/.paket/paket.bootstrapper.exe"

if [ ! -d "$SCRIPT_DIR/.paket" ]; then
  mkdir "$SCRIPT_DIR/.paket"
fi

curl -Lsfo  $PAKET_BOOTSTRAPPER $PAKET_BOOTSTRAPPER_URL

mono $PAKET_BOOTSTRAPPER


###########################################################################
# BUILD with `msbuild` for mono or with `dotnet` for dotnet core
###########################################################################

mono $SCRIPT_DIR/.paket/paket.exe install

# Nuget restor
#mono $SCRIPT_DIR/.nuget/nuget.exe restore

# .Net build restor with `msbuild`
msbuild . -t:restore
#"$SCRIPT_DIR/.dotnet/dotnet" msbuild . -t:restore

msbuild . -p:Configuration=Release
#"$SCRIPT_DIR/.dotnet/dotnet" build --config Release
