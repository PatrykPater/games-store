#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

#Depending on the operating system of the host machines(s) that will build or run the containers, the image specified in the FROM statement may need to be changed.
#For more information, please see https://aka.ms/containercompat

FROM mcr.microsoft.com/dotnet/aspnet:5.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build
WORKDIR /src
COPY ["O-gym/O-gym.csproj", "O-gym/"]
COPY ["O-gym.Application/O-gym.Application.csproj", "O-gym.Application/"]
COPY ["O-gym.Domain/O-gym.Domain.csproj", "O-gym.Domain/"]
COPY ["O-gym.Infrastructure/O-gym.Infrastructure.csproj", "O-gym.Infrastructure/"]
COPY ["O-gym.Shared/O-gym.Shared.csproj", "O-gym.Shared/"]
COPY ["O-gym.Shared.Abstractions/O-gym.Shared.Abstractions.csproj", "O-gym.Shared.Abstractions/"]
COPY ["Tests/O-gym.Tests.Common/O-gym.Tests.Common.csproj", "Tests/O-gym.Tests.Common/"]
COPY ["Tests/O-gym.Domain.Tests/O-gym.Domain.Tests.csproj", "Tests/O-gym.Domain.Tests/"]
COPY ["Tests/O-gym.Application.Tests/O-gym.Application.Tests.csproj", "Tests/O-gym.Application.Tests/"]

RUN dotnet restore "O-gym/O-gym.csproj"
COPY . .

WORKDIR "/src/O-gym"
RUN dotnet build "O-gym.csproj" -c Release -o /app/build

FROM build AS test
LABEL test=true
RUN dotnet test -c Release --results-directory /testresults --logger "trx;LogFileName=test_common.trx" Tests/O-gym.Tests.Common/O-gym.Tests.Common.csproj
RUN dotnet test -c Release --results-directory /testresults --logger "trx;LogFileName=test_domain.trx" Tests/O-gym.Domain.Tests/O-gym.Domain.Tests.csproj
RUN dotnet test -c Release --results-directory /testresults --logger "trx;LogFileName=test_application.trx" Tests/O-gym.Application.Tests/O-gym.Application.Tests.csproj

FROM build AS publish
RUN dotnet publish "O-gym.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "O-gym.dll"]