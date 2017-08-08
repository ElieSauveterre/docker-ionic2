FROM     ubuntu:16.10
MAINTAINER contact [at] eliesauveterre [dot] com

ENV DEBIAN_FRONTEND=noninteractive \
    ANDROID_HOME=/opt/android-sdk-linux \
    NODE_VERSION=6.11.2 \
    NPM_VERSION=3.10.10 \
    IONIC_VERSION=2.2.1 \
    BOWER_VERSION=1.7.7 \
    CORDOVA_VERSION=6.5.0 \
    GRUNT_VERSION=0.1.13 \
    GULP_VERSION=3.9.1 \
    SUPPLY_VERSION=1.0.0

# Install basics
RUN apt-get update &&  \
    apt-get install -y git wget curl unzip gcc make g++ ruby rubygems ruby-dev ruby-all-dev vim && \
    curl --retry 3 -SLO "http://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" && \
    tar -xzf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 && \
    rm "node-v$NODE_VERSION-linux-x64.tar.gz" && \
    npm install -g npm@"$NPM_VERSION" && \
    npm install -g grunt-cli@"$GRUNT_VERSION" bower@"$BOWER_VERSION"  cordova@"$CORDOVA_VERSION" ionic@"$IONIC_VERSION" gulp@"$GULP_VERSION" && \
    npm cache clear

# Install Sass
RUN gem install sass

# Install FireBase
RUN npm install -g firebase-tools

# Install typings
RUN npm install -g typings

#ANDROID
#JAVA

# install python-software-properties (so you can do add-apt-repository)
RUN apt-get update &&  \
    apt-get install -y -q python-software-properties software-properties-common  && \
    add-apt-repository ppa:webupd8team/java -y && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get update && apt-get -y install oracle-java8-installer


#ANDROID STUFF
RUN echo ANDROID_HOME="${ANDROID_HOME}" >> /etc/environment && \
    dpkg --add-architecture i386 && \
    apt-get install -y --force-yes expect ant wget gradle libc6-i386 lib32stdc++6 lib32gcc1 lib32ncurses5 lib32z1 qemu-kvm kmod && \
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Android SDK
RUN cd /opt && \
    wget https://dl.google.com/android/android-sdk_r24.4.1-linux.tgz && \
    tar xzf android-sdk_r24.4.1-linux.tgz && \
    rm android-sdk_r24.4.1-linux.tgz

# Setup environment
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:/opt/tools
RUN echo "export PATH=/opt/android-sdk-linux/build-tools/23.0.2:/opt/android-sdk-linux/tools/tools:/opt/android-sdk-linux/tools/platform-tools:/opt/tools:$PATH" >> /root/.bashrc
RUN echo "export ANDROID_HOME=/opt/android-sdk-linux" >> /root/.bashrc

COPY android-accept-licenses.sh /opt/tools/

# Install sdk elements
RUN ["/opt/tools/android-accept-licenses.sh", "android update sdk --filter tools --no-ui --force -a"]
RUN ["/opt/tools/android-accept-licenses.sh", "android update sdk --filter platform-tools --no-ui --force -a"]
RUN ["/opt/tools/android-accept-licenses.sh", "android update sdk --filter \"build-tools-23.0.2\" --no-ui --force -a"]
RUN ["/opt/tools/android-accept-licenses.sh", "android update sdk --filter \"extra-android-support\" --no-ui --force -a"]
RUN ["/opt/tools/android-accept-licenses.sh", "android update sdk --filter \"android-23\" --no-ui --force -a"]
RUN ["/opt/tools/android-accept-licenses.sh", "android update sdk --filter \"extra-android-m2repository\" --no-ui --force -a"]
RUN ["/opt/tools/android-accept-licenses.sh", "android update sdk --filter \"extra-google-m2repository\" --no-ui --force -a"]
RUN ["/opt/tools/android-accept-licenses.sh", "android update sdk --filter \"extra-google-play_billing\" --no-ui --force -a"]

RUN mkdir ${ANDROID_HOME}/licenses
RUN echo "8933bad161af4178b1185d1a37fbf41ea5269c55" > ${ANDROID_HOME}/licenses/android-sdk-license

# Install Fastlane Supply for APK publishing
RUN gem install --no-ri --no-rdoc supply -v ${SUPPLY_VERSION}

# Pre download/install the version of gradle used for the installed version of cordova
# for faster CI build
RUN cd /tmp \
    && export NPM_CONFIG_CACHE=/tmp/.npm \
    && export NPM_CONFIG_TMP=/tmp/.npm-tmp \
    && mkdir -p \
        /tmp/.npm \
        /tmp/.npm-tmp \
    && echo n | ionic start test-app tabs \
    && cd test-app \
    && ionic platform add android \
    && ionic build android \
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
RUN apt-get -y autoclean
RUN apt-get -y clean
RUN apt-get -y autoremove

VOLUME ["/myApp"]

WORKDIR myApp
EXPOSE 8100 35729 5037 9222 5554 5555

CMD ["ionic", "serve"]
