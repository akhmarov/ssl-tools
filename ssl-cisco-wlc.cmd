@echo off

rem #
rem # Name: ssl-cisco-wlc.cmd
rem #
rem # Date: June 2015
rem #
rem # Author: Vladimir Akhmarov
rem #
rem # Description: Cisco Wireless LAN Controller certificates (Management and WebAuth) extractor
rem #
rem # Usage:
rem #        1. Log in to Cisco Wireless LAN Controller as user with administrative privileges
rem #        2. Navigate to MANAGEMENT -> HTTP-HTTPS
rem #        3. Select checkbox Download SSL certificate and fill necessary field
rem #        4. Press Apply button
rem #        5. Navigate to SECURITY -> WebAuth -> Certificate
rem #        6. Select checkbox Download SSL certificate and fill necessary field
rem #        7. Press Apply button
rem #        8. Navigate to COMMANDS -> Reboot
rem #        9. Press Save and Reboot button
rem #

set WORK_DIR=data\cisco-wlc
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

rem Extracting client certificate to %WORK_DIR%\mgmt-cert.pem
%OPENSSL% pkcs12 -in %CERT_PFX% -out %WORK_DIR%\mgmt-cert.pem -passin pass:%PFX_PASS% -nokeys -clcerts
rem Remove bag attributes from certificate file
%OPENSSL% x509 -in %WORK_DIR%\mgmt-cert.pem -out %WORK_DIR%\mgmt-cert.pem
rem Extracting private key to %WORK_DIR%\mgmt-key.pem
%OPENSSL% pkcs12 -in %CERT_PFX% -out %WORK_DIR%\mgmt-key.pem -passin pass:%PFX_PASS% -nocerts -passout pass:%PEM_PASS%
rem Extracting PKCS12 archive to %WORK_DIR%\mgmt-arch.pem
%OPENSSL% pkcs12 -in %WORK_DIR%\mgmt-cert.pem -out %WORK_DIR%\mgmt-arch.p12 -export -inkey %WORK_DIR%\mgmt-key.pem -passin pass:%PEM_PASS% -passout pass:%PEM_PASS% -clcerts
%OPENSSL% pkcs12 -in %WORK_DIR%\mgmt-arch.p12 -out %WORK_DIR%\mgmt-arch.pem -passin pass:%PEM_PASS% -passout pass:%PEM_PASS%

rem Extracting client certificate to %WORK_DIR%\wa-cert-cl.pem
%OPENSSL% pkcs12 -in %CERT_PFX% -out %WORK_DIR%\wa-cert-cl.pem -passin pass:%PFX_PASS% -nokeys -clcerts
rem Remove bag attributes from client, intermediate and root certificate files
%OPENSSL% x509 -in %WORK_DIR%\wa-cert-cl.pem -out %WORK_DIR%\wa-cert-cl.pem
%OPENSSL% x509 -in %CERT_INTR% -out %WORK_DIR%\ca-intr.pem
%OPENSSL% x509 -in %CERT_ROOT% -out %WORK_DIR%\ca-root.pem
rem Combine client, intermediate and root certificates into one file
copy /b %WORK_DIR%\wa-cert-cl.pem+%WORK_DIR%\ca-intr.pem+%WORK_DIR%\ca-root.pem %WORK_DIR%\wa-cert.pem
rem Extracting private key to %WORK_DIR%\wa-key.pem
%OPENSSL% pkcs12 -in %CERT_PFX% -out %WORK_DIR%\wa-key.pem -passin pass:%PFX_PASS% -nocerts -passout pass:%PEM_PASS%
rem Extracting PKCS12 archive to %WORK_DIR%\wa-arch.pem
%OPENSSL% pkcs12 -in %WORK_DIR%\wa-cert.pem -out %WORK_DIR%\wa-arch.p12 -export -inkey %WORK_DIR%\wa-key.pem -passin pass:%PEM_PASS% -passout pass:%PEM_PASS% -clcerts
%OPENSSL% pkcs12 -in %WORK_DIR%\wa-arch.p12 -out %WORK_DIR%\wa-arch.pem -passin pass:%PEM_PASS% -passout pass:%PEM_PASS%

echo Archive (Management): %WORK_DIR%\mgmt-arch.pem (password: %PEM_PASS%)
echo Archive (WebAuth): %WORK_DIR%\wa-arch.pem (password: %PEM_PASS%)

echo WARNING! All files will be deleted!

:QUIT
pause

rem Delete all files in working dir
del /f /q %WORK_DIR%\*.*
