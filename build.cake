// tools
#tool paket:?package=xunit.runner.console&version=2.4.1
#tool paket:?package=JetBrains.ReSharper.CommandLineTools&version=2019.2.2

// addins
#addin paket:?package=Cake.Figlet&version=1.3.1
#addin paket:?package=Cake.Paket&version=4.0

var target = Argument<string>("target", "Default");
var configuration = Argument<string>("configuration", "Release");

Verbosity verbosity;
switch (Argument<string>("verbosity", "verbose"))
{
    case "quiet":
      verbosity = Verbosity.Quiet;
      break;
    case "minimal":
      verbosity = Verbosity.Minimal;
      break;
    case "normal":
      verbosity = Verbosity.Normal;
      break;
    case "verbose":
      verbosity = Verbosity.Verbose;
      break;
    case "diagnostic":
      verbosity = Verbosity.Diagnostic;
      break;
}

Task("Clean")
  .Does(() =>
{
  CleanDirectories("./src/**/" + configuration);
  CleanDirectories("./test/**/" + configuration);
});

Task("Restore")
  .Does(() =>
{
   MSBuild("./CBT.sln", configurator =>
    configurator.WithTarget("Restore")
    .SetVerbosity(Verbosity.Minimal));
});

Task("Compile")
  .IsDependentOn("Clean")
  .IsDependentOn("Restore")
  .Does(() =>
{
   MSBuild("./CBT.sln", configurator =>
    configurator.SetConfiguration(configuration)
        .WithTarget("Rebuild")
        .SetVerbosity(verbosity)
        .UseToolVersion(MSBuildToolVersion.VS2017)
        .SetMSBuildPlatform(MSBuildPlatform.x86)
        .SetPlatformTarget(PlatformTarget.MSIL));
});

Task("Publish")
  .Description("Gathers output files and copies them to the output folder")
  .IsDependentOn("Compile")
  .Does(() =>
  {

  });

Task("Default")
  .IsDependentOn("Compile")
  .Does(() =>
{
  Information(Figlet("HVG Build System"));
});

RunTarget(target);
