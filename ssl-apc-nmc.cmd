@echo off

rem #
rem # Name: ssl-apc-nmc.cmd
rem #
rem # Date: March 2017
rem #
rem # Author: Vladimir Akhmarov
rem #
rem # Description: APC Network Management Card certificate extractor
rem #
rem # Usage:
rem #        1. 
rem #

set WORK_DIR=data\apc-nmc
set CERT_PFX=data\archive.pfx
set PEM_PASS=check123

if exist C:\OpenSSL-Win32\bin\openssl.exe (
	set OPENSSL=C:\OpenSSL-Win32\bin\openssl.exe
) else if exist C:\OpenSSL-Win64\bin\openssl.exe (
	set OPENSSL=C:\OpenSSL-Win64\bin\openssl.exe
) else (
	echo No OpenSSL binary found. Terminating...
	goto QUIT
)

if not exist %CERT_PFX% (
	echo No PFX file found. Terminating...
	goto QUIT
)

cls

set /p PFX_PASS=Enter PFX password:

rem Extracting client certificate to %WORK_DIR%\cl-cert-tmp.pem
%OPENSSL% pkcs12 -in %CERT_PFX% -out %WORK_DIR%\cl-cert-tmp.pem -passin pass:%PFX_PASS% -nokeys -clcerts
rem Remove bag attributes from certificate file
%OPENSSL% x509 -in %WORK_DIR%\cl-cert-tmp.pem -out %WORK_DIR%\cl-cert.pem
rem Extracting private key to %WORK_DIR%\cl-key.pem
%OPENSSL% pkcs12 -in %CERT_PFX% -out %WORK_DIR%\cl-key.pem -passin pass:%PFX_PASS% -nocerts -nodes
rem Convert private key to PKCS#15 format


echo Certificate: %WORK_DIR%\cl-cert.pem
echo Private key: %WORK_DIR%\cl-key.p15

echo WARNING! All files will be deleted!

:QUIT
pause

rem Delete all files in working dir
del /f /q %WORK_DIR%\*.*
