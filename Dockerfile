FROM public.ecr.aws/amazonlinux/amazonlinux:2

RUN yum install -y \
    dialog \
    jq