@echo off

:: Main Code
set original_path=%cd%

:: Constants
set nimrod_git_url="git://github.com/Araq/Nimrod.git"
set csources_git_url="git://github.com/nimrod-code/csources.git"
set default_nimrod_branch=master
set default_csources_branch=master
set default_nimrod_directory="Nimrod"
set default_csources_directory="csources"

set default_arch="64"
echo %PROCESSOR_ARCHITECTURE% | findstr "64"
if ERRORLEVEL 1 set arch="32"


:: Get the installation path
:get_install_path
set /P nimrod_directory="Installation path? (default: 'Nimrod')"
if "%nimrod_directory%"=="" set nimrod_directory="Nimrod"
if EXIST %nimrod_directory% (
	choice /C "cr" /M "Warning, target directory exists. [C]ontinue, or [R]e-input path name?" 
	if ERRORLEVEL 1 (
		goto:get_install_path
	)
)

:: Clone the Nimrod and csource respositories
echo.
git clone %nimrod_git_url% %nimrod_directory%
call:check_for_error

cd %nimrod_directory%

echo.
git clone %csources_git_url% csources
call:check_for_error


:: Checkout the selected branches.
:checkout_branches
echo.
echo Select a branch by number, or type in an alternate branch name (default: %default_nimrod_branch%)
echo [1] - Master
echo [2] - Devel
echo [3] - BigBreak

set /P selected_nimrod_branch="Branch? "
if "%selected_nimrod_branch%"=="" (
	set selected_nimrod_branch=%default_nimrod_branch%
	set selected_csources_branch=%default_csources_branch%
) else if "%selected_nimrod_branch%"=="1" (
	set selected_nimrod_branch="master"
	set selected_csources_branch="master"
) else if "%selected_nimrod_branch%"=="2" (
	set selected_nimrod_branch="devel"
	set selected_csources_branch="devel"
) else if "%selected_nimrod_branch%"=="3" (
	set selected_nimrod_branch="bigbreak"
	set selected_csources_branch="bigbreak"
) else (
	set /P selected_csources_branch="Which csources branch should be used?"
)

git checkout %selected_nimrod_branch%
if ERRORLEVEL 1 (
	echo Couldn't check out the branch '%selected_nimrod_branch%'
	goto:checkout_branches
	)

cd csources
git checkout %selected_csources_branch%
if ERRORLEVEL 1 (
	echo Couldn't check out the branch '%selected_csources_branch%'
	cd ..
	goto:checkout_branches
	)


:: Build the basic nimrod binary
:build_csources_binary
echo Target architecture? This should match the default architecture the C compiler targets.
echo Valid options are '32' and '64' (default: %arch%)
set /P arch=""
if "%arch%"=="" (
	set arch=%default_arch%
) else if "%arch%"=="32" (
	call build.bat
) else if "%arch%"=="64" (
	call build64.bat
) else (
	echo Invalid architecture %arch%
	goto:build_csources_binary
)

:: Build final binary
cd ..
.\bin\nimrod c koch
call:check_for_error
.\koch boot -d:release
call:check_for_error


exit /B
:: Subroutines

:check_for_error
setlocal
if ERRORLEVEL 1 (
	choice /C "cq" /M "Possible error encountered. [C]ontinue, or [Q]uit?"
	if ERRORLEVEL 2 (
			exit /B
		)
	)
endlocal
goto:EOF