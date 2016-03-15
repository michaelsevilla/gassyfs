FROM centos:7.1.1503

RUN echo "===> Install the basics..." && \
    yum remove -y iputils systemd && \
    yum update -y && \
    yum install -y \
      autoconf \
      bzip2 \
      curl \
      fuse \
      fuse-devel \
      gettext \
      gcc \
      gcc-c++ \
      git \
      libibverbs-utils \
      libibverbs-devel \
      libipathverbs \
      make \
      ncurses-devel \
      openssh-client \
      openssh-server \
      readline-devel \
      sudo \
      tar \
      wget \
      zlib-devel && \
    yum groupinstall -y --setopt=group_package_types=optional "Infiniband Support" && \
    yum clean -y all
 

RUN echo "===> Install samtools..." && \
    wget https://github.com/samtools/samtools/releases/download/1.3/samtools-1.3.tar.bz2 && \
    tar xjf samtools-1.3.tar.bz2 && \
    cd samtools-1.3 && \
    make && \
    make install

RUN echo "===> Make users and add tty for sudo..." && \
    groupadd fuse && \
    usermod -a -G fuse root && \
    sed -i -e "s/Defaults    requiretty.*/ #Defaults    requiretty/g" /etc/sudoers

RUN echo "===> Install GassyFS" && \
    wget https://raw.githubusercontent.com/noahdesu/gassyfs/master/ci/install-gasnet.sh && \
    chmod 755 install-gasnet.sh && \
    ./install-gasnet.sh

# * modify sshd conf
# * workaround for the way ubuntu deals with env for sudo
# * create expected dirs/links
RUN sed -i "s/UsePAM.*/UsePAM yes/" /etc/ssh/sshd_config && \
    sed -i "s/AcceptEnv LANG LC_*/#AcceptEnv LANG LC_*/" /etc/ssh/sshd_config && \
    echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:" > /etc/environment && \
    echo "alias sudo='sudo env PATH=\$PATH'" >> /etc/environment && \
    sed -i "s/Defaults.*env_reset//" /etc/sudoers && \
    sed -i "s/Defaults.*secure_path.*//" /etc/sudoers

ADD entrypoint.sh /
ADD configure_ssh.sh /
RUN chmod 755 /entrypoint.sh /configure_ssh.sh
ENTRYPOINT ["/entrypoint.sh"]
