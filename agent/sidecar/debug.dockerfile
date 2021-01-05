FROM alpine:3.12
LABEL maintainer="support@overops.com"

ARG AGENT_VERSION=latest

# install dependencies
RUN apk add curl
RUN mkdir /takipi

# rootless
RUN addgroup -g 1000 overops
RUN adduser -D -h /opt/takipi -u 1000 -G overops overops
RUN chown overops:overops takipi

USER 1000:1000

# set working directory
WORKDIR /opt

# download and install the agent - extracts into the `takipi` folder.
# NOTE for Alpine, use: overops/agent-sidecar:alpine-latest
RUN curl -sL https://s3.amazonaws.com/app-takipi-com/deploy/linux/takipi-agent-${AGENT_VERSION}.tar.gz | tar -xvzf - ; chmod -R 777 takipi/

# print version
RUN cat takipi/VERSION

# share /takipi between containers in a pod
VOLUME ["/takipi/"]

WORKDIR /opt/takipi

# create a run script to copy /opt/takipi/ (latest agent) to /takipi/ (shared)
RUN echo "#!/bin/sh" > run.sh \
 && echo "cat /opt/takipi/VERSION" >> run.sh \
 && echo "cp -a /opt/takipi/. /takipi/" >> run.sh \
 && echo "while [ ! -f /takipi/log/agents/*.log ] && [ ! -f /takipi/log/agents/bugtail_agent.startup ]; do" >> run.sh \
 && echo "sleep 2" >> run.sh \
 && echo "echo 'waiting for jvm startup'" >> run.sh \
 && echo "done" >> run.sh \
 && echo "tail -f /takipi/log/agents/*.log -f /takipi/log/agents/bugtale_agent.startup" >> run.sh \
 && chmod +x run.sh

CMD ["./run.sh"]
