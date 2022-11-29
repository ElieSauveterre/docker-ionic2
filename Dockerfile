FROM ubuntu:20.04
MAINTAINER contact [at] eliesauveterre [dot] com

ENV DEBIAN_FRONTEND=noninteractive \
    NODE_VERSION=12.22.1 \
    NPM_VERSION=6.14.12 \
    IONIC_VERSION=6.12.4 \
    CORDOVA_VERSION=8.1.2 \
    FASTLANE_VERSION=2.211.0

# Local mirrors
RUN echo "deb mirror://mirrors.ubuntu.com/mirrors.txt focal main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb mirror://mirrors.ubuntu.com/mirrors.txt focal-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb mirror://mirrors.ubuntu.com/mirrors.txt focal-security main restricted universe multiverse" >> /etc/apt/sources.list && \
    apt-get update

# Install basics
RUN apt-get update &&  \
    apt-get install -y git wget curl unzip gcc make g++ vim xvfb libgtk2.0-0 libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 imagemagick jq && \
    curl --retry 3 -SLO "http://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" && \
    tar -xzf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 && \
    rm "node-v$NODE_VERSION-linux-x64.tar.gz"

# Install AWS tools
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

RUN npm install -g npm@"$NPM_VERSION" npmrc @ionic/cli@"$IONIC_VERSION" firebase-tools typings native-run

# Install Sass
RUN apt-get install -y ruby-full rubygems ruby-dev libffi-dev
RUN gem install sass

# ANDROID
# JAVA
# install python-software-properties (so you can do add-apt-repository)
RUN apt-get install -y openjdk-11-jdk

#ANDROID STUFF
ENV ANDROID_HOME=/opt/android-sdk-linux

RUN echo ANDROID_HOME="${ANDROID_HOME}" >> /etc/environment && \
    dpkg --add-architecture i386 && \
    apt-get install -y expect ant wget gradle libc6-i386 lib32stdc++6 lib32gcc1 lib32z1 qemu-kvm kmod && \
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Android SDK
ENV ANDROID_SDK_VERSION='9123335' \
    ANDROID_BUILD_TOOLS_VERSION=32.0.0 \
    ANDROID_APIS="android-32"

RUN cd /opt && \
    mkdir android-sdk-linux && \
    cd android-sdk-linux && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip

RUN cd $ANDROID_HOME && \
    mkdir .android && \
    unzip commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip && \
    rm commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip

# Setup environment
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:/opt/tools
RUN echo "export PATH=/opt/android-sdk-linux/build-tools/${ANDROID_BUILD_TOOLS_VERSION}:/opt/android-sdk-linux/tools:/opt/android-sdk-linux/platform-tools:/opt/tools:$PATH" >> /root/.bashrc
RUN echo "export ANDROID_HOME=/opt/android-sdk-linux" >> /root/.bashrc

# Install sdk elements
RUN mkdir /root/.android && \
    touch /root/.android/repositories.cfg
RUN yes | $ANDROID_HOME/cmdline-tools/bin/sdkmanager --licenses --sdk_root=${ANDROID_HOME}
RUN $ANDROID_HOME/cmdline-tools/bin/sdkmanager "tools" --sdk_root=${ANDROID_HOME}
RUN $ANDROID_HOME/cmdline-tools/bin/sdkmanager "platform-tools" --sdk_root=${ANDROID_HOME}
RUN $ANDROID_HOME/cmdline-tools/bin/sdkmanager "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" --sdk_root=${ANDROID_HOME}
RUN $ANDROID_HOME/cmdline-tools/bin/sdkmanager "platforms;${ANDROID_APIS}" --sdk_root=${ANDROID_HOME}
RUN $ANDROID_HOME/cmdline-tools/bin/sdkmanager "extras;android;m2repository" --sdk_root=${ANDROID_HOME}
RUN $ANDROID_HOME/cmdline-tools/bin/sdkmanager "extras;google;m2repository" --sdk_root=${ANDROID_HOME}

# Install Fastlane for APK publishing
RUN gem install rake
RUN gem install fastlane -v ${FASTLANE_VERSION}
RUN gem install bundler:1.17.3
RUN gem cleanup


RUN mkdir myApp

### Clean
RUN npm cache clear --force
RUN apt-get -y autoclean
RUN apt-get -y clean
RUN apt-get -y autoremove

VOLUME ["/myApp"]

WORKDIR myApp
EXPOSE 8100 35729 5037 9222 5554 5555

CMD ["ionic", "serve"]
