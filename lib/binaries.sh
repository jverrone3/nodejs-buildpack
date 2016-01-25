needs_resolution() {
  local semver=$1
  if ! [[ "$semver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    return 0
  else
    return 1
  fi
}

install_nodejs() {
  local version="$1"
  local dir="$2"

  if needs_resolution "$version"; then
    echo "Resolving node version ${version:-(latest stable)} via semver.io..."
    version=$($BP_DIR/bin/node $BP_DIR/lib/version_resolver.js "$version")
  fi

  echo "Downloading and installing node $version..."
  local download_url="http://s3pository.heroku.com/node/v$version/node-v$version-$os-$cpu.tar.gz"
  curl "`translate_dependency_url $download_url`" --silent --fail -o /tmp/node.tar.gz || (>&2 $BP_DIR/compile-extensions/bin/recommend_dependency $download_url && false)
  echo "Downloaded [`translate_dependency_url $download_url`]"
  tar xzf /tmp/node.tar.gz -C /tmp
  rm -rf $dir/*
  mv /tmp/node-v$version-$os-$cpu/* $dir
  chmod +x $dir/bin/*
}

install_oracle() {
  local dir="$1"
  
  echo "Downloading the Oracle Instant Client BASIC and SDK zip..."
  local download_url="http://oracledb-node.apps-np.homedepot.com/instantclient-basic-linux.x64-12.1.0.2.0.zip"
  curl "$download_url" --silent --fail -o /tmp/instantclientbasic.zip || (echo "Unabled to download Oracle BASIC zip." && false)
  local download_url="http://oracledb-node.apps-np.homedepot.com/instantclient-sdk-linux.x64-12.1.0.2.0.zip"
  curl "$download_url" --silent --fail -o /tmp/instantclientsdk.zip || (echo "Unabled to download Oracle SDK zip." && false)
  echo "Installing the Oracle Instant Client Basic..."
  unzip /tmp/instantclientbasic.zip
  echo "Installing the Oracle Instant Client SDK..."
  unzip -o /tmp/instantclientsdk.zip
  echo "mkdir instantclientbasic..."
  mkdir -p $dir/instantclientbasic

  mv /tmp/instantclientbasic/* $dir/instantclientbasic
  mv /tmp/instantclientsdk/* $dir/instantclientbasic
  
  echo "ln -s libclntsh.sh"
  ln -s $dir/instantclientbasic/libclntsh.so.12.1 $dir/instantclientbasic/libclntsh.so

  echo "Set the link path..."
  export LD_LIBRARY_PATH=$dir/instantclientbasic:$LD_LIBRARY_PATH
  export OCI_LIB_DIR=$dir/instantclientbasic
  export OCI_INC_DIR=$dir/instantclientbasic/sdk/include
}

install_iojs() {
  local version="$1"
  local dir="$2"

  if needs_resolution "$version"; then
    echo "Resolving iojs version ${version:-(latest stable)} via semver.io..."
    version=$(curl --silent --get --data-urlencode "range=${version}" https://semver.herokuapp.com/iojs/resolve)
  fi

  echo "Downloading and installing iojs $version..."
  local download_url="https://iojs.org/dist/v$version/iojs-v$version-$os-$cpu.tar.gz"
  curl "$download_url" --silent --fail -o /tmp/node.tar.gz || (echo "Unable to download iojs $version; does it exist?" && false)
  tar xzf /tmp/node.tar.gz -C /tmp
  mv /tmp/iojs-v$version-$os-$cpu/* $dir
  chmod +x $dir/bin/*
}

install_npm() {
  local version="$1"

  if [ "$version" == "" ]; then
    echo "Using default npm version: `npm --version`"
  else
    if needs_resolution "$version"; then
      echo "Resolving npm version ${version} via semver.io..."
      version=$(curl --silent --get --data-urlencode "range=${version}" https://semver.herokuapp.com/npm/resolve)
    fi
    if [[ `npm --version` == "$version" ]]; then
      echo "npm `npm --version` already installed with node"
    else
      echo "Downloading and installing npm $version (replacing version `npm --version`)..."
      npm install --unsafe-perm --quiet -g npm@$version 2>&1 >/dev/null
    fi
  fi
}
