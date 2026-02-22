FROM fedora:39

# 1. Install Java, wget, unzip, git
RUN dnf install -y java-17-openjdk-devel wget unzip git which && dnf clean all

# 2. Install Android SDK Command Line Tools
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools
ARG SDK_VERSION=11076708

RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-${SDK_VERSION}_latest.zip -O sdk.zip && \
    unzip sdk.zip -d $ANDROID_SDK_ROOT/cmdline-tools && \
    mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest && \
    rm sdk.zip

# 3. Accept Licenses and install Platform Tools + Build Tools
RUN yes | sdkmanager --licenses && \
    sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# 4. Install a standalone Gradle specifically for the 'init' command
ENV GRADLE_VERSION=8.5
RUN wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -O gradle.zip && \
    unzip gradle.zip -d /opt && \
    rm gradle.zip
ENV PATH=$PATH:/opt/gradle-${GRADLE_VERSION}/bin

WORKDIR /workspace
