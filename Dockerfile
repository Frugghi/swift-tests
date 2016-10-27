FROM ubuntu:14.04

# Setup envs
ENV SWIFT_BRANCH=swift-3.0-release \
    SWIFT_VERSION=swift-3.0-RELEASE \
    KUBECTL_VERSION=1.4.0 \
    KUBECONFIG=/kubeconfig/kube-config \
    WORKDIR=/swift-tests

# Install Swift and Kubectl
#
# Swift dependencies:
# binutils     - required by Swift compiler (on Ubuntu 14.04)
# clang        - required by Swift compiler
# libedit2     - required by Swift (on Ubuntu 14.04)
# libicu-dev   - required by Swift
# libpython2.7 - required by LLDB / REPL
# libxml2      - required by LLDB / REPL
# git          - required by Swift Package Manager
RUN apt-get -qq update \
 && DEBIAN_FRONTEND=noninteractive apt-get -qq install --no-install-recommends ca-certificates curl clang git binutils libedit2 libicu-dev libpython2.7 libxml2 >/dev/null \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && curl -sSLo /usr/local/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
 && chmod +x /usr/local/bin/kubectl \
 && curl -sSLo swift.tar.gz "https://swift.org/builds/${SWIFT_BRANCH}/ubuntu1404/${SWIFT_VERSION}/${SWIFT_VERSION}-ubuntu14.04.tar.gz" \
 && tar -zxf swift.tar.gz -C / --strip 1 \
 && rm -f swift.tar.gz \
 && mkdir -p "${WORKDIR}" \
 && mkdir -p "$(dirname "${KUBECONFIG}")"

 WORKDIR "${WORKDIR}"

# Compile dependencies
# (Yaml-3.0.0 doesn't compile on Linux, apply a patch for now)
COPY Package.swift ./
RUN bash -c 'swift build | sed "/.*\/Packages\/Yaml-3.0.0\/Yaml\// { N; N; d; }"; exit 0' 2>/dev/null \
 && echo "import Foundation\n\n#if os(Linux)\ntypealias NSRegularExpression = RegularExpression\n#endif\n" | sudo tee ./Packages/Yaml-3.0.0/Yaml/LinuxPatch.swift > /dev/null \
 && swift build

# Compile the app
COPY Sources ./Sources/
RUN swift build \
 && mkdir -p ./Results \
 && mkdir -p ./Resources

# Set the entrypoint
ENTRYPOINT ["./.build/debug/swift-tests"]
