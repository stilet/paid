FROM ubuntu:16.04

RUN export DEBIAN_FRONTEND=noninteractive \
    && sed -i 's,http://archive.ubuntu.com/ubuntu/,mirror://mirrors.ubuntu.com/mirrors.txt,' /etc/apt/sources.list \
    && apt-get update -qq && apt-get upgrade -qq \

    && apt-get install -y --no-install-recommends \
        nginx-light \
        python3 \
        python3-pip \
        python3-setuptools \
        python3-psycopg2 \

    && BUILD_DEPS='build-essential python3-dev' \
    && apt-get install -y --no-install-recommends ${BUILD_DEPS} \

    && pip3 install --no-cache-dir \
        circus==0.13.0 \
        gunicorn==19.7.1 \
        iowait==0.2 \
        psutil==5.4.0 \
        pyzmq==16.0.3 \
        tornado==4.5.2 \

    && apt-get autoremove -y ${BUILD_DEPS} \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY requirements.txt /opt/sun/app/
RUN pip3 install --no-cache-dir -r /opt/sun/app/requirements.txt

COPY etc/ /etc/
COPY sun/ /opt/sun/app/

WORKDIR /opt/sun/app
ENV STATIC_ROOT=/opt/sun/static
RUN nginx -t \
    && python3 -c 'import compileall, os; compileall.compile_dir(os.curdir, force=1)' > /dev/null \
    && ./manage.py collectstatic --settings=sun.settings --no-input -v0
CMD ["circusd", "/etc/circus/web.ini"]
