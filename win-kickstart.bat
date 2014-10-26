@echo off
setlocal
:: Main Code
set original_path=%cd%

:: Constants
set nimrod_git_url="git://github.com/Araq/Nimrod.git"
set csources_git_url="git://github.com/nimrod-code/csources.git"

:: Prompt the user for information
call:prompt_for_install_path selected_install_path
call:prompt_for_branches selected_nim_branch selected_csources_branch
call:prompt_for_build_arch selected_build_arch


:: Clone the Nimrod and csource respositories
echo.
git clone %nimrod_git_url% %selected_install_path%
call:check_for_error

cd %selected_install_path%

echo.
git clone %csources_git_url% csources
call:check_for_error


:: Checkout the selected branches.
:checkout_branches
git checkout %selected_nim_branch%
if ERRORLEVEL 1 (
	echo Couldn't check out the branch '%selected_nim_branch%'
	echo [R]eselect branch, or [Q]uit?
	choice /C "rq" /N /M ""
	if ERRORLEVEL 2 (
		call:exit_batch
	) else (
		call:prompt_for_branches
		goto:checkout_branches
	)
)

@cd csources
git checkout %selected_csources_branch%
if ERRORLEVEL 1 (
	echo Couldn't check out the branch '%selected_nim_branch%'
	echo [R]eselect branch, or [Q]uit?
	choice /C "rq" /N /M ""
	if ERRORLEVEL 2 (
		call:exit_batch
	) else (
		cd ..
		call:prompt_for_branches
		goto:checkout_branches
	)
)


:: Build the basic nimrod binary
if "%selected_build_arch%"=="32" (
	call build.bat
) else if "%selected_build_arch%"=="64" (
	call build64.bat
)

:: Build final binary
cd ..
.\bin\nimrod c koch
call:check_for_error
.\koch boot -d:release
call:check_for_error

:end
endlocal
exit /B
@echo off

:: Subroutines

:: Get the installation path
:prompt_for_install_path
setlocal

	set default_nimrod_directory=Nimrod

	:prompt_for_install_path_start
	echo Installation path? (default: "%default_nimrod_directory%")
	set /P nimrod_directory=""
	if "%nimrod_directory%"=="" set nimrod_directory="%default_nimrod_directory%"
	if EXIST %nimrod_directory% (
		echo Warning, target directory exists. [C]ontinue, or [R]e-input path name?
		choice /C "cr" /N /M "" 
		if ERRORLEVEL 2 (
			echo.
			goto:prompt_for_install_path_start
		)
	)
echo.
endlocal & set %~1=%nimrod_directory%
goto:EOF

:: Prompts the user to select a Nim and csources branch.
:: Defaults to devel for both.
:prompt_for_branches
setlocal

	set default_nimrod_branch=devel
	set default_csources_branch=devel

	:prompt_for_branches_start
	echo Select a branch by number, or type in an alternate branch name 
	echo (default: %default_nimrod_branch%)
	echo [1] - Master
	echo [2] - Devel
	echo [3] - BigBreak

	set /P nim_branch=""
	if "%nim_branch%"=="" (
		set nim_branch=%default_nimrod_branch%
		set selected_csources_branch=%default_csources_branch%
	) else if "%nim_branch%"=="1" (
		set nim_branch=master
		set selected_csources_branch=master
	) else if "%nim_branch%"=="2" (
		set nim_branch=devel
		set selected_csources_branch=devel
	) else if "%nim_branch%"=="3" (
		set nim_branch=bigbreak
		set selected_csources_branch=bigbreak
	) else (
		echo Which csources branch should be used?
		set /P selected_csources_branch=""
		echo Warning: Nonstandard branch configuration being used.
	)

echo.
endlocal & set %~1=%nim_branch%& set %~2=%selected_csources_branch%
goto:EOF


:: Prompts the user to select a bitness - either 32 or 64 - defaulting to the
:: bitness of their system.
:: Returns either '32' or '64' through the variable r1
:prompt_for_build_arch
setlocal enabledelayedexpansion

	echo %PROCESSOR_ARC"HITECTURE% | findstr "64" > NUL
	if ERRORLEVEL 1 set default_arch=32
	set default_arch=64

	:prompt_for_build_arch_start
	echo Target architecture? This should match the default architecture the 
	echo C compiler targets.
	echo Valid options are '32' and '64' (default: %default_arch%)
	set /P arch=""
	if "%arch%"=="" (
		set arch=%default_arch%
	) else if "%arch%"=="32" (
		goto:prompt_for_build_arch_end
	) else if "%arch%"=="64" (
		goto:prompt_for_build_arch_end
	) else (
		echo Invalid architecture '%arch%'
		echo.
		goto:prompt_for_build_arch_start
	)

:prompt_for_build_arch_end
endlocal & set %~1=%arch%
goto:EOF


:: Checks if the last program returned an error code, and shows a selection to
:: either continue or quit if there is.
:check_for_error
if ERRORLEVEL 1 (
	echo Possible error encountered. [C]ontinue, or [Q]uit?
	choice /C "cq" /N /M ""
	if ERRORLEVEL 2 (
			call:exit_batch
		)
	)
echo.
goto:EOF

:: Cleanly exits batch processing, regardless of where we are
:exit_batch
if not exist "%temp%\exit_batch_yes.txt" call :build_yes
call :CtrlC <"%temp%\exit_batch_yes.txt" 1>nul 2>&1
:CtrlC
cmd /c exit -1073741510

:build_yes
pushd "%temp%"
set "yes="
copy nul exit_batch_yes.txt >nul
for /f "delims=(/ tokens=2" %%Y in (
  '"copy /-y nul exit_batch_yes.txt <nul"'
) do if not defined yes set "yes=%%Y"
echo %yes%>exit_batch_yes.txt
popd
exit /b