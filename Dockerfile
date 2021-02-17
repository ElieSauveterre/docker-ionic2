FROM openjdk:8-jdk-alpine

ENV ANDROID_HOME=/opt/android-sdk-linux \
    ANDROID_SDK_VERSION='6200805' \
    ANDROID_BUILD_TOOLS_VERSION=29.0.3 \
    ANDROID_APIS="android-29" \
    FASTLANE_VERSION=2.137.0 \
    NODE_VERSION=10.19.0 \
    NPM_VERSION=6.7.0 \
    IONIC_VERSION=5.3.0 \
    CORDOVA_VERSION=8.1.2

RUN apk add --no-cache bash git nodejs npm
RUN apk add --no-cache --virtual .ruby-builddeps \
    unzip \
    wget \
    make \
    ruby-dev \
    g++ \
    python3
RUN apk add --virtual .rundeps $runDeps

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
RUN yes | $ANDROID_HOME/tools/bin/sdkmanager --licenses --sdk_root=${ANDROID_HOME}
RUN $ANDROID_HOME/tools/bin/sdkmanager "tools" --sdk_root=${ANDROID_HOME}
RUN $ANDROID_HOME/tools/bin/sdkmanager "platform-tools" --sdk_root=${ANDROID_HOME}
RUN $ANDROID_HOME/tools/bin/sdkmanager "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" --sdk_root=${ANDROID_HOME}
RUN $ANDROID_HOME/tools/bin/sdkmanager "platforms;${ANDROID_APIS}" --sdk_root=${ANDROID_HOME}
RUN $ANDROID_HOME/tools/bin/sdkmanager "extras;android;m2repository" --sdk_root=${ANDROID_HOME}
RUN $ANDROID_HOME/tools/bin/sdkmanager "extras;google;m2repository" --sdk_root=${ANDROID_HOME}

# Install Fastlane for APK publishing
RUN gem install --no-ri --no-rdoc fastlane -v ${FASTLANE_VERSION}
RUN gem cleanup

# Install Node
RUN npm install --unsafe-perm=true -g npm@"$NPM_VERSION" npmrc cordova@"$CORDOVA_VERSION" ionic@"$IONIC_VERSION" firebase-tools typings native-run bit-bin
RUN npm install -g cordova-res --unsafe-perm=true --allow-root

# Install Python and AWS tools
RUN wget https://bootstrap.pypa.io/get-pip.py
RUN python3.6 get-pip.py
RUN echo "export PATH=/root/.local/bin:$PATH" >> /root/.bashrc
RUN export PATH=/root/.local/bin:$PATH
RUN pip install awsebcli==3.10.1 --upgrade --user
RUN pip install --upgrade --user awscli

RUN rm -rf /tmp/* && \
    rm -rf /var/cache/apk/* && \
    npm cache clear --force

RUN mkdir myApp

VOLUME ["/myApp"]

WORKDIR myApp
EXPOSE 8100 35729 5037 9222 5554 5555

CMD ["ionic", "serve"]

