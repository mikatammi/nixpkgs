{ lib
, stdenv
, buildPythonPackage
, fetchFromGitHub
, flatten-dict
, funcy
, matplotlib
, tabulate
, pytestCheckHook
, pytest-mock
, pytest-test-utils
, pythonOlder
, setuptools-scm
}:

buildPythonPackage rec {
  pname = "dvc-render";
  version = "0.5.0";
  format = "pyproject";

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "iterative";
    repo = pname;
    rev = "refs/tags/${version}";
    hash = "sha256-x9vb8X7p4MOMZwr91ronXB/bPZD3PqYhbzLccRewyco=";
  };

  SETUPTOOLS_SCM_PRETEND_VERSION = version;

  nativeBuildInputs = [
    setuptools-scm
  ];

  passthru.optional-dependencies = {
    table = [
      flatten-dict
      tabulate
    ];
    markdown = [
      tabulate
      matplotlib
    ];
  };

  nativeCheckInputs = [
    funcy
    pytestCheckHook
    pytest-mock
    pytest-test-utils
  ]
  ++ passthru.optional-dependencies.table
  ++ passthru.optional-dependencies.markdown;

  disabledTestPaths = lib.optionals stdenv.isDarwin [
    "tests/test_vega.py"
  ];

  pythonImportsCheck = [
    "dvc_render"
  ];

  meta = with lib; {
    description = "Library for rendering DVC plots";
    homepage = "https://github.com/iterative/dvc-render";
    changelog = "https://github.com/iterative/dvc-render/releases/tag/${version}";
    license = licenses.asl20;
    maintainers = with maintainers; [ fab ];
  };
}
