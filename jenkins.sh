# Expected Files:
#   ~/.nuget/NuGet.exe
#
# Expected Jenkins Variables:
#   $WORKSPACE - defined by Jenkins
#
# Parameterized Build Variables (strings): 
#   $SolutionName - Name of solution file relative to workspace directory, without .sln
#                   Usually equivalent to the Jenkins project name.
#   $ProjectName - Project name of whatever we're releasing. e.g. ProjectName.csproj.
#
# Build Environment Parameters:
#   $Major - Major Version Number (indicates breaking changes).
#   $Minor - Minor Version Number (indicates new features but continued compatability).
#   $Patch - Patch Version Number (indicates bugfixes and minor optimizations).
#   $Stage - Pre-release stage. Set to nothing ("") to indicate stable release.
#
# Release Version Template: ${Major}.${Minor}.${Patch}-${Stage}

# Required Variables: (none)
function buildSolution() {
   pushd "${WORKSPACE}";
   mono ~/.nuget/NuGet.exe restore "${SolutionName}.sln";
   xbuild /p:Configuration=Release "${SolutionName}.sln";
   popd;
}

function releaseSubPackage() {
   echo "hello! ${Major}.${Minor}.${Patch}-${Stage}";
   
   pushd "${WORKSPACE}/${ProjectName}"; 
   
   releasePackageHelper;
}

# Required Variables:
#   $ProjectPage - probably the link to the project repository.
#   $ProjectLicense - link to project license.
#   $PackageProfile - see NuGet Target column of http://embed.plnkr.co/03ck2dCtnJogBKHJ9EjY/preview
function releasePackage() {
   echo "hello! ${Major}.${Minor}.${Patch}-${Stage}";
   echo "${WORKSPACE}/.nuget/NuGet.exe";
   
   pushd "${WORKSPACE}"; 
   releasePackageHelper;
}

function releasePackageHelper {
   if [[ -z "${Stage}" ]]; then
     PACKAGE_VERSION="${Major}.${Minor}.${Patch}";
   else
     PACKAGE_VERSION="${Major}.${Minor}.${Patch}-${Stage}";
   fi
 
   # generate *.nuspec file for our project
   echo "Generating nuspec file: ";
   mono ~/.nuget/NuSpecGen.exe -p "${ProjectName}" -v "${PACKAGE_VERSION}" -l "${ProjectLicense}" -u "${ProjectPage}" -t "${PackageProfile}";
   
   # print nuspec file to console
   echo "Printing generated nuspec file: ";
   cat "${ProjectName}.nuspec";
   echo "";
   
   # remove all nuget packages, pack new nuget package
   echo "Removing previously generated nupkg files: ";
   rm -f *.nupkg;
   echo "";
   
   echo "Running nuget pack with the nuspec file: ";
   mono ~/.nuget/NuGet.exe pack "${ProjectName}.nuspec" -Verbose -Prop Configuration=Release;
   echo "";
   
   # push to NuGet repository
   echo "Pushing nuget package to repository: ";
   mono ~/.nuget/NuGet.exe push "${ProjectName}.${PACKAGE_VERSION}.nupkg" -Source http://nuget.dargon.io/;
   echo "";
   
   popd;
}