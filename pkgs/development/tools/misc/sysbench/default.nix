{ lib
, stdenv
, fetchFromGitHub
, autoreconfHook
, pkg-config
, libmysqlclient
, libaio
, luajit
# For testing:
, testers
, sysbench
}:

stdenv.mkDerivation rec {
  pname = "sysbench";
  version = "1.0.20";

  nativeBuildInputs = [ autoreconfHook pkg-config libmysqlclient ];
  buildInputs = [ libmysqlclient luajit ] ++ lib.optionals stdenv.isLinux [ libaio ];

  src = fetchFromGitHub {
    owner = "akopytov";
    repo = pname;
    rev = version;
    sha256 = "1sanvl2a52ff4shj62nw395zzgdgywplqvwip74ky8q7s6qjf5qy";
  };

  enableParallelBuilding = true;

  postPatch = ''
    substituteInPlace configure.ac --replace "pkg-config" "$PKG_CONFIG"
  '' +
  # concurrency_kit's configure script tries to check whether binaries built by
  # compiler run, which of course fails because the binary has been
  # cross-compiled. Disable the check when cross-compiling.
  lib.optionalString (!stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    substituteInPlace \
      third_party/concurrency_kit/ck/configure \
      --replace \
        'COMPILER=`./.1 2> /dev/null`' \
        "COMPILER=gcc" \
      --replace \
        'PLATFORM=`uname -m 2> /dev/null`' \
        "PLATFORM=aarch64"
  '';
  configureFlags = [
    # The bundled version does not build on aarch64-darwin:
    # https://github.com/akopytov/sysbench/issues/416
    "--with-system-luajit"
  ];

  passthru.tests = {
    versionTest = testers.testVersion {
      package = sysbench;
    };
  };

  meta = {
    description = "Modular, cross-platform and multi-threaded benchmark tool";
    longDescription = ''
      sysbench is a scriptable multi-threaded benchmark tool based on LuaJIT.
      It is most frequently used for database benchmarks, but can also be used
      to create arbitrarily complex workloads that do not involve a database
      server.
    '';
    homepage = "https://github.com/akopytov/sysbench";
    downloadPage = "https://github.com/akopytov/sysbench/releases/tag/${version}";
    changelog = "https://github.com/akopytov/sysbench/blob/${version}/ChangeLog";
    license = lib.licenses.gpl2;
    platforms = lib.platforms.unix;
  };
}
