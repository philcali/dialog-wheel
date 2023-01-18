FROM public.ecr.aws/ubuntu/ubuntu:latest

RUN apt-get update -yq
RUN apt-get install -yq \
    dialog \
    bc \
    jq

COPY wheel /usr/bin/wheel
COPY styles/default /root/.dialogrc

WORKDIR /wheel
ENTRYPOINT [ "/usr/bin/wheel/main.sh" ]