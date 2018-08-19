@echo off

rem #
rem # Name: tls-cisco-wms.cmd
rem #
rem # Date: March 2017
rem #
rem # Author: Vladimir Akhmarov
rem #
rem # Description: Cisco WebEx Meeting Server certificates extractor
rem #
rem # Usage:
rem #        1. Log in to Cisco WebEx Meeting Server as user with administrative privileges
rem #        2. Navigate to WebEx Administration interface
rem #        3. Navigate to Settings -> Security -> Certificates on CWMS System
rem #        4. Press Internal SSL Certificate -> More Options
rem #        5. Select Import SSL Certificate/private key
rem #        6. Select certificate chain file, fill Passphrase field with value 'check123' without quotes
rem #        7. Press Continue button (system will enter Maintenance mode)
rem #        8. Navigate to Dashboard
rem #        9. Press Manage Maintenance Mode button
rem #        10. Unselect checkbox CWMS System (Maintenance) and press Save button
rem #

set WORK_DIR=data\cisco-wms
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

rem Extract client certificate to %WORK_DIR%\cl-cert-tmp.pem
%OPENSSL% pkcs12 -in %CERT_PFX% -out %WORK_DIR%\cl-cert-tmp.pem -passin pass:%PFX_PASS% -nokeys -clcerts
rem Remove bag attributes from client and intermediate certificate files
%OPENSSL% x509 -in %WORK_DIR%\cl-cert-tmp.pem -out %WORK_DIR%\cl-cert.pem
%OPENSSL% x509 -in %CERT_INTR% -out %WORK_DIR%\ca-intr.pem
rem Extract private key to %WORK_DIR%\cl-key.pem
%OPENSSL% pkcs12 -in %CERT_PFX% -out %WORK_DIR%\cl-key12.pem -passin pass:%PFX_PASS% -nocerts -passout pass:%PEM_PASS%
rem Convert private key from PKCS#12 to PKCS#8 format
%OPENSSL% pkcs8 -in %WORK_DIR%\cl-key12.pem -out %WORK_DIR%\cl-key8.pem -topk8 -inform pem -outform pem -passin pass:%PEM_PASS% -passout pass:%PEM_PASS%

rem Combine private key, client and intermediate certificates into one file
copy /b %WORK_DIR%\cl-key8.pem+%WORK_DIR%\ca-intr.pem+%WORK_DIR%\cl-cert.pem %WORK_DIR%\cl-chain.pem

echo Chain: %WORK_DIR%\cl-chain.pem (password: %PEM_PASS%)

echo WARNING! All files will be deleted!

:QUIT
pause

rem Delete all files in working dir
del /f /q %WORK_DIR%\*.*
