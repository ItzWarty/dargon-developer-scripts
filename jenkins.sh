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

# Required Variables:
#   $ProjectPage - probably the link to the project repository.
#   $ProjectLicense - link to project license.
#   $PackageProfile - see NuGet Target column of http://embed.plnkr.co/03ck2dCtnJogBKHJ9EjY/preview
function releasePackage() {
   echo "hello! ${Major}.${Minor}.${Patch}-${Stage}";
   echo "${WORKSPACE}/.nuget/NuGet.exe";
   
   pushd "${WORKSPACE}"; 
   
   # Turn Shell Script Tracing Off
   set +x;
   
   ASSEMBLY_INFO="$(cat Properties/AssemblyInfo.cs)";
   ASSEMBLY_TITLE="$(echo \"$ASSEMBLY_INFO\" | grep AssemblyTitle | sed -n -e 's/.*AssemblyTitle\w*(\w*"//p' | sed -n -e 's/")].*//p')";
   ASSEMBLY_AUTHORS="$(echo \"$ASSEMBLY_INFO\" | grep AssemblyCompany | sed -n -e 's/.*AssemblyCompany\w*(\w*"//p' | sed -n -e 's/")].*//p')";
   ASSEMBLY_DESCRIPTION="$(echo \"$ASSEMBLY_INFO\" | grep AssemblyDescription | sed -n -e 's/.*AssemblyDescription\w*(\w*"//p' | sed -n -e 's/")].*//p')";
   ASSEMBLY_COPYRIGHT="$(echo \"$ASSEMBLY_INFO\" | grep AssemblyCopyright | sed -n -e 's/.*AssemblyCopyright\w*(\w*"//p' | sed -n -e 's/")].*//p')";
   
   mono ~/.nuget/NuGet.exe spec "${ProjectName}" -f;
   
   sed -i -e "s/[$]id[$]/${ProjectName}/" "${ProjectName}.nuspec" > /dev/null;
   if [[ -z "${Stage}" ]]; then
     PACKAGE_VERSION="${Major}.${Minor}.${Patch}";
   else
     PACKAGE_VERSION="${Major}.${Minor}.${Patch}-${Stage}";
   fi
      
   sed -i -e "s/[$]version[$]/${PACKAGE_VERSION}/" "${ProjectName}.nuspec" > /dev/null;
   sed -i -e "s/[$]title[$]/${ASSEMBLY_TITLE}/" "${ProjectName}.nuspec" > /dev/null;
   sed -i -e "s/[$]author[$]/${ASSEMBLY_AUTHORS}/" "${ProjectName}.nuspec" > /dev/null;
   sed -i -e "s/[$]description[$]/${ASSEMBLY_DESCRIPTION}/" "${ProjectName}.nuspec" > /dev/null;
   sed -i -e "s/[$]description[$]/${ASSEMBLY_DESCRIPTION}/" "${ProjectName}.nuspec" > /dev/null;
   sed -i -e "s|http://PROJECT_URL_.*_LINE|${ProjectPage}|" "${ProjectName}.nuspec" > /dev/null;
   
   # delete icon url line
   sed -i '/iconUrl/d' "${ProjectName}.nuspec" > /dev/null;
   
   # delete tags line
   sed -i '/tags/d' "${ProjectName}.nuspec" > /dev/null;
   
   # Project License
   sed -i -e "s|http://LICENSE_URL_.*_LINE|${ProjectLicense}|" "${ProjectName}.nuspec" > /dev/null;
   
   # Add Release to lib/net45 of output
   sed -i "/\/metadata/a \
     <files> \
       <file src=\"bin/Release/**/*.*\" target=\"lib/${PackageProfile}\\\" /> \
     <\/files>" "${ProjectName}.nuspec" > /dev/null;
   
   # Turn Shell Script Tracing On
   set -x;
   
   # remove all nuget packages, pack new nuget package
   rm -f *.nupkg;
   mono ~/.nuget/NuGet.exe pack "${ProjectName}.nuspec" -Verbose -Prop Configuration=Release;
   
   # push to NuGet repository
   mono ~/.nuget/NuGet.exe push "${ProjectName}.${PACKAGE_VERSION}.nupkg" -Source http://nuget.dargon.io/
   
   popd;
}