{
  cudaPackages,
  feature ? null,
  lib,
  libraries,
  name ? if feature == null then "torch-compile-cpu" else "torch-compile-${feature}",
  pythonPackages,
  stdenv,
}:
let
  deviceStr = if feature == null then "" else '', device="cuda"'';
in
(cudaPackages.writeGpuTestPython.override { python3Packages = pythonPackages; })
  {
    inherit name feature libraries;
    makeWrapperArgs = [
      "--suffix"
      "PATH"
      ":"
      "${lib.getBin stdenv.cc}/bin"
    ];
  }
  (
    ''
      import torch


    ''
    +
      # torch.compile requires OpenMP which is not available on Darwin
      lib.optionalString (!stdenv.hostPlatform.isDarwin) ''
        @torch.compile
      ''
    + ''
      def opt_foo2(x, y):
          a = torch.sin(x)
          b = torch.cos(y)
          return a + b


      print(
        opt_foo2(
          torch.randn(10, 10${deviceStr}),
          torch.randn(10, 10${deviceStr})))
    ''
    +
      # MPS is built by default on Darwin, so test it.
      lib.optionalString stdenv.hostPlatform.isDarwin ''
        assert torch.backends.mps.is_built(), "PyTorch not build with MPS enabled"
        if not torch.backends.mps.is_available():
            print("MPS not available because the current MacOS version is not 12.3+ "
                  "and/or you do not have an MPS-enabled device on this machine.")

        else:
            print(
              opt_foo2(
                torch.randn(10, 10, device="mps"),
                torch.randn(10, 10, device="mps")))
      ''
  )
