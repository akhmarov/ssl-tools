@echo off

rem #
rem # Name: tls-hpkp.cmd
rem #
rem # Date: March 2017
rem #
rem # Author: Vladimir Akhmarov
rem #
rem # Description: Public Key Pinning Extension for HTTP (RFC 7469) header extractor
rem #

set WORK_DIR=data\hpkp
set CERT_PFX=data\archive.pfx
set CERT_INTR=data\ca-intr.crt

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
rem Remove bag attributes from client certificate file
%OPENSSL% x509 -in %WORK_DIR%\cl-cert-tmp.pem -out %WORK_DIR%\cl-cert.pem
rem Remove bag attributes from intermediate certificate file
%OPENSSL% x509 -in %CERT_INTR% -out %WORK_DIR%\ca-intr.pem
rem Create BASE64 encoded SHA256 hash of the client certificate
for /f "tokens=*" %%I in ('%OPENSSL% x509 -in %WORK_DIR%\cl-cert.pem -pubkey -noout ^| %OPENSSL% rsa -pubin -outform der ^| %OPENSSL% dgst -sha256 -binary ^| %OPENSSL% enc -base64') do set BASE64_CL=%%I
rem Create BASE64 encoded SHA256 hash of the intermediate CA certificate
for /f "tokens=*" %%I in ('%OPENSSL% x509 -in %WORK_DIR%\ca-intr.pem -pubkey -noout ^| %OPENSSL% rsa -pubin -outform der ^| %OPENSSL% dgst -sha256 -binary ^| %OPENSSL% enc -base64') do set BASE64_CA=%%I

echo Public Key Pinning Extension for HTTP
echo Public-Key-Pins: pin-sha256="%BASE64_CL%"; pin-sha256="%BASE64_CA%"; max-age=5184000; includeSubdomains;

:QUIT
pause

rem Delete all files in working dir
del /f /q %WORK_DIR%\*.*
