@echo off

rem #
rem # Name: ssl-hpe-msa.cmd
rem #
rem # Date: May 2017
rem #
rem # Author: Vladimir Akhmarov
rem #
rem # Description: HPE Modular Smart Array (MSA) certificates extractor
rem #
rem # Usage:
rem #        1. Log in to HPE Modular Smart Array (MSA) via FTP
rem #        2. Enter FTP passive mode with command "quote pasv"
rem #        3. Put certificate file with command "put cert.pem cert-file"
rem #        4. Put private key file with command "put key.pem cert-key-file"
rem #        5. Restart both management controllers
rem #

set WORK_DIR=data\hpe-msa
set CERT_PFX=data\archive.pfx
set CERT_INTR=data\ca-intr.crt
set CERT_ROOT=data\ca-root.crt
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

rem Extracting client certificate to %WORK_DIR%\cert-cl-tmp.pem
%OPENSSL% pkcs12 -in %CERT_PFX% -out %WORK_DIR%\cert-cl-tmp.pem -passin pass:%PFX_PASS% -nokeys -clcerts
rem Remove bag attributes from client, intermediate and root certificate files
%OPENSSL% x509 -in %WORK_DIR%\cert-cl-tmp.pem -out %WORK_DIR%\cert-cl.pem
%OPENSSL% x509 -in %CERT_INTR% -out %WORK_DIR%\ca-intr.pem
%OPENSSL% x509 -in %CERT_ROOT% -out %WORK_DIR%\ca-root.pem
rem Combine client, intermediate and root certificates into one file
copy /b %WORK_DIR%\cert-cl.pem+%WORK_DIR%\ca-intr.pem+%WORK_DIR%\ca-root.pem %WORK_DIR%\cert.pem
rem Extracting private key to %WORK_DIR%\key-tmp.pem
%OPENSSL% pkcs12 -in %CERT_PFX% -out %WORK_DIR%\key-tmp.pem -passin pass:%PFX_PASS% -nocerts -passout pass:%PEM_PASS%
rem Remove passphrase from private key file
%OPENSSL% rsa -in %WORK_DIR%\key-tmp.pem -out %WORK_DIR%\key.pem -passin pass:%PEM_PASS%

echo Certificate: %WORK_DIR%\cert.pem
echo Private key: %WORK_DIR%\key.pem

echo WARNING! All files will be deleted!

:QUIT
pause

rem Delete all files in working dir
del /f /q %WORK_DIR%\*.*
