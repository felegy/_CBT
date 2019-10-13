#!/usr/bin/env bash

# Define directories.
SCRIPT_DIR=$PWD

# Define default arguments.
SCRIPT="build.cake"
TARGET="Default"
CONFIGURATION="Release"
VERBOSITY="verbose"
DRYRUN=
SHOW_VERSION=false
SCRIPT_ARGUMENTS=()

# Used to convert relative paths to absolute paths.
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
function twoAbsolutePath {
    cd ~ && cd $SCRIPT_DIR
    absolutePath=$(cd $1 && pwd)
    echo $absolutePath
}

function get_latest_release {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

PAKET=".paket"
CAKE=".cake"
PACKAGES="packages"
TOOLS="$PACKAGES/tools"
ADDINS="$PACKAGES/addins"
MODULES="$PACKAGES/modules"

DOTNET_VERSION=$(cat "$SCRIPT_DIR/global.json" | grep -o '[0-9]\.[0-9]\.[0-9][0-9][0-9]')
DOTNET_INSTRALL_URI=https://raw.githubusercontent.com/dotnet/cli/master/scripts/obtain/dotnet-install.sh

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

DOTNET="$SCRIPT_DIR/.dotnet/dotnet"

export DOTNET_ROOT="$SCRIPT_DIR/.dotnet"

###########################################################################


###########################################################################
# INSTALL PAKET Dependecy resolver
###########################################################################

echo "Installing Paket..."

# Make sure the .paket directory exits.
if [ ! -d $PAKET ]; then
  mkdir $PAKET
fi

PAKET_DIR=$(twoAbsolutePath $PAKET)

# Set paket directory enviornment variable.
export PAKET=$PAKET_DIR
export PATH="$PAKET_DIR":$PATH

#PAKET_EXE=$PAKET_DIR/paket.exe
PAKET_EXE=$PAKET_DIR/paket

if [ ! -f "$PAKET_EXE" ]; then
  $DOTNET tool install Paket --tool-path $PAKET
fi

if [ ! -f "$PAKET_EXE" ]; then
  echo "Could not find paket tool at '$PAKET_EXE'."
  exit 1
fi

###########################################################################
# INSTALL NuGet Package manager
###########################################################################

echo "Installing NuGet..."

if [ ! -d "$SCRIPT_DIR/.nuget" ]; then
  mkdir "$SCRIPT_DIR/.nuget"
fi

curl -Lsfo "$SCRIPT_DIR/.nuget/nuget.exe" https://dist.nuget.org/win-x86-commandline/latest/nuget.exe

###########################################################################
# INSTALL Cake // C# make
###########################################################################

echo "Installing Cake..."

#export CAKE_SETTINGS_SKIPPACKAGEVERSIONCHECK=true

# Make sure the .cake directory exits.
if [ ! -d $CAKE ]; then
  mkdir $CAKE
fi

CAKE_DIR=$(twoAbsolutePath $CAKE)

# Set cake directory enviornment variable.
export CAKE=$CAKE_DIR
export PATH="$CAKE_DIR":$PATH

#CAKE_EXE=$CAKE_DIR/cake.exe
CAKE_EXE=$CAKE_DIR/dotnet-cake

if [ ! -f "$CAKE_EXE" ]; then
  $DOTNET tool install Cake.Tool --tool-path $CAKE_DIR
fi

if [ ! -f "$CAKE_EXE" ]; then
  echo "Could not find cake tool at '$CAKE_EXE'."
  exit 1
fi

echo "Paket Restore ..."
#mono $PAKET_EXE" restore
$PAKET_EXE restore

# tools
if [ -d "$TOOLS" ]; then
    TOOLS_DIR=$(twoAbsolutePath $TOOLS)
    export CAKE_PATHS_TOOLS=$TOOLS_DIR
else
    echo "Could not find tools directory at '$TOOLS'."
fi

# addins
if [ -d "$ADDINS" ]; then
    ADDINS_DIR=$(twoAbsolutePath $ADDINS)
    export CAKE_PATHS_ADDINS=$ADDINS_DIR
else
    echo "Could not find addins directory at '$ADDINS'."
fi

# modules
if [ -d "$MODULES" ]; then
    MODULES_DIR=$(twoAbsolutePath $MODULES)
    export CAKE_PATHS_MODULES=$MODULES_DIR
else
    echo "Could not find modules directory at '$MODULES'."
fi

###########################################################################
# Cake BUILD start
###########################################################################

# Start Cake.
if $SHOW_VERSION; then
    #exec mono "$CAKE_EXE" -version
    exec "$CAKE_EXE" -version
else
    echo "Cake BUILD Starting ..."
    #exec mono "$CAKE_EXE" $SCRIPT "$@"
    exec "$CAKE_EXE" $SCRIPT "$@"
fi
