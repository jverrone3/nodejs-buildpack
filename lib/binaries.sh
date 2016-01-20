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

install_oraclerpm() {
  echo "Downloading and installing oracle BASIC rpm..."
  local download_url="http://download.oracle.com/otn/linux/instantclient/121020/oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm"
  curl "$download_url" --silent --fail -o /tmp/oracle || (echo "Unabled to download Oracle BASIC rpm." && false)
  rpm -ivh /tmp/oracle/oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm
  echo "Downloading and installing oracle SDK rpm..."
  local download_url="http://download.oracle.com/otn/linux/instantclient/121020/oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm"
  curl "$download_url" --silent --fail -o /tmp/oracle || (echo "Unabled to download Oracle SDK rpm." && false)
  rpm -ivh /tmp/oracle/oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm
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
