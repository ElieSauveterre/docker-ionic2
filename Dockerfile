FROM     ubuntu:18.04
MAINTAINER contact [at] eliesauveterre [dot] com

ENV DEBIAN_FRONTEND=noninteractive \
    NODE_VERSION=8.15.0 \
    NPM_VERSION=6.7.0 \
    IONIC_VERSION=5.3.0 \
    CORDOVA_VERSION=8.1.2 \
    GULP_VERSION=3.9.1 \
    FASTLANE_VERSION=2.137.0

# Install basics
RUN apt-get update &&  \
    apt-get install -y git wget curl unzip gcc make g++ vim xvfb libgtk2.0-0 libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 && \
    curl --retry 3 -SLO "http://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" && \
    tar -xzf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 && \
    rm "node-v$NODE_VERSION-linux-x64.tar.gz"

# Install Python and AWS tools
RUN wget https://bootstrap.pypa.io/get-pip.py
RUN python3.6 get-pip.py
RUN echo "export PATH=/root/.local/bin:$PATH" >>                        /root/.bashrc
RUN export PATH=/root/.local/bin:$PATH
RUN pip install awsebcli==3.10.1 --upgrade --user
RUN pip install --upgrade --user awscli

RUN npm install -g npm@"$NPM_VERSION" npmrc cordova@"$CORDOVA_VERSION" ionic@"$IONIC_VERSION" gulp@"$GULP_VERSION" firebase-tools typings native-run
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
    ANDROID_SDK_VERSION='4333796' \
    ANDROID_BUILD_TOOLS_VERSION=28.0.3 \
    ANDROID_APIS="android-28"

RUN echo ANDROID_HOME="${ANDROID_HOME}" >> /etc/environment && \
    dpkg --add-architecture i386 && \
    apt-get install -y --force-yes expect ant wget gradle libc6-i386 lib32stdc++6 lib32gcc1 lib32ncurses5 lib32z1 qemu-kvm kmod && \
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
