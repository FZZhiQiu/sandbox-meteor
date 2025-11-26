# 使用预配置的Android SDK环境
FROM thyrlian/android-sdk:latest

# 安装必要的工具
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    wget \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/*

# 设置Java环境
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk
ENV ANDROID_HOME=/opt/android-sdk-linux
ENV PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

# 设置工作目录
WORKDIR /workspace

# 复制项目文件
COPY . .

# 确保gradlew可执行
RUN chmod +x ./gradlew

# 接受Android SDK许可证
RUN yes | sdkmanager --licenses || true

# 构建APK
RUN ./gradlew assembleDebug --no-daemon -x test -x lint \
    -Dorg.gradle.jvmargs="-Xmx2g -XX:MaxMetaspaceSize=512m" \
    --console=plain

# 暴露APK位置
VOLUME ["/workspace/app/build/outputs/apk/debug/"]

CMD ["ls", "-la", "/workspace/app/build/outputs/apk/debug/"]