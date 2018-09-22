@echo off

rem #
rem # Name: tls-cisco-asa.cmd
rem #
rem # Date: September 2018
rem #
rem # Author: Vladimir Akhmarov
rem #
rem # Description: Synology Disk Station Manager certificate extractor
rem #
rem # Usage:
rem #        1. Log in to Synology DSM

rem #

set WORK_DIR=data\syno-dsm
set CERT_PFX=data\archive.pfx
set CERT_INTR=data\ca-intr.crt
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
rem Remove bag attributes from client and intermediate certificate files
%OPENSSL% x509 -in %WORK_DIR%\cl-cert-tmp.pem -out %WORK_DIR%\cl-cert.pem
%OPENSSL% x509 -in %CERT_INTR% -out %WORK_DIR%\ca-intr.pem
rem Extracting private key to %WORK_DIR%\cl-key.pem
%OPENSSL% pkcs12 -in %CERT_PFX% -out %WORK_DIR%\cl-key-tmp.pem -passin pass:%PFX_PASS% -nocerts -passout pass:%PEM_PASS%
rem Remove bag attributes from private key file
%OPENSSL% x509 -in %WORK_DIR%\cl-key-tmp.pem -out %WORK_DIR%\cl-key-tmp.pem
rem Remove passphrase from private key file
%OPENSSL% rsa -in %WORK_DIR%\cl-key-tmp.pem -out %WORK_DIR%\cl-key.pem -passin pass:%PEM_PASS%

copy /b %CERT_INTR% %WORK_DIR%\ca-intr.pem

echo Private Key (Client): %WORK_DIR%\cl-key.pem
echo Certificate (Client): %WORK_DIR%\cl-cert.pem
echo Certificate (Intermediate): %WORK_DIR%\ca-intr.pem

echo WARNING! All files will be deleted!

:QUIT
pause

rem Delete all files in working dir
del /f /q %WORK_DIR%\*.*
