ARG JULIA_VERSION=1
FROM julia:${JULIA_VERSION}

# Options for common setup script
# Install zsh & Oh-My-Zsh
ARG INSTALL_ZSH="true"
# Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="true"
ARG COMMON_SCRIPT_SOURCE="https://raw.githubusercontent.com/microsoft/vscode-dev-containers/master/script-library/common-debian.sh"
ARG COMMON_SCRIPT_SHA="dev-mode"

# This Dockerfile adds a non-root user with sudo access. Update the “remoteUser” property in
# devcontainer.json to use it. More info: https://aka.ms/vscode-remote/containers/non-root-user.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Install needed packages and setup non-root user.
RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends curl ca-certificates 2>&1 \
    && curl -sSL  ${COMMON_SCRIPT_SOURCE} -o /tmp/common-setup.sh \
    && ([ "${COMMON_SCRIPT_SHA}" = "dev-mode" ] || (echo "${COMMON_SCRIPT_SHA} */tmp/common-setup.sh" | sha256sum -c -)) \
    && /bin/bash /tmp/common-setup.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "false" \
    && rm /tmp/common-setup.sh \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

RUN RUN wget https://julialang-s3.julialang.org/bin/linux/x64/1.8/julia-1.8.4-linux-x86_64.tar.gz && \
    tar -xvzf julia-1.8.4-linux-x86_64.tar.gz && \
    mv julia-1.8.4 /usr/lib/ && \
    ln -s /usr/lib/julia-1.8.4/bin/julia /usr/bin/julia && \
    rm julia-1.8.4-linux-x86_64.tar.gz && \
    julia -e "using Pkg;Pkg.add([\"IJulia\", \"Plots\" ])" && \
    julia -e "using Pkg;Pkg.add([\"ModelingToolkit\", \"ModelingToolkitStandardLibrary\"])" && \
    julia -e "using Pkg;Pkg.add([\"DifferentialEquations\", \"OrdinaryDiffEq\", \"Unitful\"])" && \
    julia -e "using Pkg;Pkg.add([\"DiffEqFlux\", \"DataDrivenDiffEq\", \"StatsPlots\", \"PlotlyJS\"])" && \
    julia -e "using Pkg;Pkg.add([\"CSV\", \"DataFrame\", \"Conda\",  \"PyCall\"])" && \
    julia -e "using Conda; Conda.pip_interop(true); Conda.pip(\"install\", \"webio_jupyter_extension\")"

RUN mkdir -p /julia-devcontainer-scripts

COPY ./postcreate.jl /julia-devcontainer-scripts

RUN chmod +x /julia-devcontainer-scripts/postcreate.jl
