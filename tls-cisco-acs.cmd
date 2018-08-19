@echo off

rem #
rem # Name: tls-cisco-acs.cmd
rem #
rem # Date: March 2017
rem #
rem # Author: Vladimir Akhmarov
rem #
rem # Description: Cisco Secure Access Control System (ACS) 5.x certificate extractor
rem #
rem # Usage:
rem #        1. Log in to Cisco Secure ACS 5.x appliance as user with SuperAdmin role
rem #        2. Navigate to System Administration -> Configuration -> Local Server Certificates -> Local Certificates
rem #        3. Press Add button
rem #        4. Select Import Server Certificate
rem #        5. Select certificate and private key files, fill Private Key Password field with value 'check123' without quotes
rem #        6. Select any required checkboxes and press Finish
rem #        7. Wait while system is restarting services
rem #

set WORK_DIR=data\cisco-acs
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
%OPENSSL% pkcs12 -in %CERT_PFX% -out %WORK_DIR%\cl-key.pem -passin pass:%PFX_PASS% -nocerts -passout pass:%PEM_PASS%

echo Certificate: %WORK_DIR%\cl-cert.pem
echo Private key: %WORK_DIR%\cl-key.pem (password: %PEM_PASS%)

echo WARNING! All files will be deleted!

:QUIT
pause

rem Delete all files in working dir
del /f /q %WORK_DIR%\*.*
