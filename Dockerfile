FROM     ubuntu:19.04
MAINTAINER contact [at] eliesauveterre [dot] com

ENV DEBIAN_FRONTEND=noninteractive \
    ANDROID_HOME=/opt/android-sdk-linux \
    NODE_VERSION=8.15.0 \
    NPM_VERSION=6.7.0 \
    IONIC_VERSION=3.20.0 \
    BOWER_VERSION=1.7.7 \
    CORDOVA_VERSION=8.0.0 \
    GRUNT_VERSION=0.1.13 \
    GULP_VERSION=3.9.1 \
    FASTLANE_VERSION=2.137.0

# Install basics
RUN apt-get update &&  \
    apt-get install -y git wget curl unzip gcc make g++ vim xvfb libgtk2.0-0 libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 libvips-dev && \
    curl --retry 3 -SLO "http://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" && \
    tar -xzf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 && \
    rm "node-v$NODE_VERSION-linux-x64.tar.gz"

# Install Python and AWS tools
RUN apt-get install -y python3-pip
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
RUN python get-pip.py
RUN pip install awsebcli==3.10.1 --upgrade --user
RUN pip install --upgrade --user awscli

RUN npm install -g npm@"$NPM_VERSION" npmrc cordova@"$CORDOVA_VERSION" ionic@"$IONIC_VERSION" gulp@"$GULP_VERSION" firebase-tools typings
RUN npm install -g cordova-res --unsafe-perm=true --allow-root

# Install Sass
RUN apt-get install -y ruby-full rubygems ruby-dev libffi-dev
RUN gem install sass

# ANDROID
# JAVA
# install python-software-properties (so you can do add-apt-repository)
RUN apt-get install -y openjdk-8-jdk

#ANDROID STUFF
ENV ANDROID_HOME=/opt/android-sdk-linux \
    ANDROID_SDK_VERSION='3859397' \
    ANDROID_BUILD_TOOLS_VERSION=26.0.2 \
    ANDROID_APIS="android-26"

RUN echo ANDROID_HOME="${ANDROID_HOME}" >> /etc/environment && \
    dpkg --add-architecture i386 && \
    apt-get install -y expect ant wget gradle libc6-i386 lib32stdc++6 lib32gcc1 lib32z1 qemu-kvm kmod && \
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Android SDK
RUN cd /opt && \
    mkdir android-sdk-linux && \
    cd android-sdk-linux && \
    wget https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_VERSION}.zip

RUN cd $ANDROID_HOME && \
    mkdir .android && \
    unzip sdk-tools-linux-${ANDROID_SDK_VERSION}.zip && \
    rm sdk-tools-linux-${ANDROID_SDK_VERSION}.zip

# Setup environment
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:/opt/tools
RUN echo "export PATH=/opt/android-sdk-linux/build-tools/${ANDROID_BUILD_TOOLS_VERSION}:/opt/android-sdk-linux/tools:/opt/android-sdk-linux/platform-tools:/opt/tools:$PATH" >> /root/.bashrc
RUN echo "export ANDROID_HOME=/opt/android-sdk-linux" >> /root/.bashrc

# Install sdk elements
RUN mkdir /root/.android && \
    touch /root/.android/repositories.cfg
RUN yes | $ANDROID_HOME/tools/bin/sdkmanager --licenses
RUN $ANDROID_HOME/tools/bin/sdkmanager "tools"
RUN $ANDROID_HOME/tools/bin/sdkmanager "platform-tools"
RUN $ANDROID_HOME/tools/bin/sdkmanager "build-tools;${ANDROID_BUILD_TOOLS_VERSION}"
RUN $ANDROID_HOME/tools/bin/sdkmanager "platforms;${ANDROID_APIS}"
RUN $ANDROID_HOME/tools/bin/sdkmanager "extras;android;m2repository"
RUN $ANDROID_HOME/tools/bin/sdkmanager "extras;google;m2repository"

# Install Fastlane for APK publishing
RUN gem install --no-ri --no-rdoc fastlane -v ${FASTLANE_VERSION}
RUN gem cleanup

# Pre download/install the version of gradle used for the installed version of cordova
# for faster CI build
RUN cd /tmp \
    && export NPM_CONFIG_CACHE=/tmp/.npm \
    && export NPM_CONFIG_TMP=/tmp/.npm-tmp \
    && mkdir -p \
        /tmp/.npm \
        /tmp/.npm-tmp \
    && git config --global user.email "you@example.com" \
    && git config --global user.name "Your Name" \
    && echo n | ionic start test-app tabs --no-interactive \
    && cd test-app \
    && ionic cordova platform add android --no-interactive \
    && ionic cordova build android --prod --no-interactive \
    && rm -rf \
        /root/.android/debug.keystore \
        /root/.config \
        /root/.cordova \
        /root/.ionic \
        /root/.v8flags.*.json \
        /tmp/.npm \
        /tmp/.npm-tmp \
        /tmp/hsperfdata_root/* \
        /tmp/ionic-starter-* \
        /tmp/native-platform*dir \
        /tmp/test-app

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
