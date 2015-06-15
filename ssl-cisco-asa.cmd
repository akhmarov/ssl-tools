@echo off

rem #
rem # Name: ssl-cisco-asa.cmd
rem #
rem # Date: June 2015
rem #
rem # Author: Vladimir Akhmarov
rem #
rem # Description: Cisco Adaptive Security Appliance certificate extractor
rem #
rem # Usage:
rem #        1. Log in to Cisco ASA Security Device Manager as user with administrative privileges
rem #        2. Navigate to Configuration -> Device Management -> Certificate Management -> CA Certificates
rem #        3. Press Add button
rem #        4. Fill Trustpoint Name field, select root certificate and press Install Certificate button
rem #        5. Press Add button
rem #        6. Fill Trustpoint Name field, select intermediate certificate and press Install Certificate button
rem #        7. Navigate to Configuration -> Device Management -> Certificate Management -> Identity Certificates
rem #

set WORK_DIR=data\cisco-asa
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

rem Extracting client certificate to %WORK_DIR%\cl-cert.pem
%OPENSSL% pkcs12 -in %CERT_PFX% -out %WORK_DIR%\cl-cert.pem -passin pass:%PFX_PASS% -nokeys -clcerts
rem Remove bag attributes from client, intermediate and root certificate files
%OPENSSL% x509 -in %WORK_DIR%\cl-cert.pem -out %WORK_DIR%\cl-cert.pem
%OPENSSL% x509 -in %CERT_INTR% -out %WORK_DIR%\ca-intr.pem
%OPENSSL% x509 -in %CERT_ROOT% -out %WORK_DIR%\ca-root.pem
rem Extracting private key to %WORK_DIR%\cl-key.pem
%OPENSSL% pkcs12 -in %CERT_PFX% -out %WORK_DIR%\cl-key.pem -passin pass:%PFX_PASS% -nocerts -passout pass:%PEM_PASS%
rem Extracting PKCS12 archive to %WORK_DIR%\cl-arch.pem
%OPENSSL% pkcs12 -in %WORK_DIR%\cl-cert.pem -out %WORK_DIR%\cl-arch.p12 -export -inkey %WORK_DIR%\cl-key.pem -passin pass:%PEM_PASS% -passout pass:%PEM_PASS% -clcerts

echo Archive: %WORK_DIR%\cl-arch.p12 (password: %PEM_PASS%)
echo Certificate (Intermediate): %WORK_DIR%\ca-intr.pem
echo Certificate (Root): %WORK_DIR%\ca-root.pem

echo WARNING! All files will be deleted!

:QUIT
pause

rem Delete all files in working dir
del /f /q %WORK_DIR%\*.*
