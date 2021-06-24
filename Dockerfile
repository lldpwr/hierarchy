FROM mcr.microsoft.com/powershell:7.0.3-debian-10
RUN pwsh -c 'Install-Module -Name Pode.Kestrel -Confirm:$false -force'
WORKDIR /usr/src/app/
COPY . .
EXPOSE 8086
CMD ["./startserver.ps1"]