FROM ubuntu:16.04

MAINTAINER Gabriele Prato <gabriele.prato@mail.polimi.it>
LABEL name="SparkUndeploying"

# Install Python.
RUN \
  apt-get update && \
  apt-get install -y python python-dev python-pip python-virtualenv && \
  rm -rf /var/lib/apt/lists/*

# Install Dirmngr to fix error in R installation
RUN \
  apt-get update && \
  apt-get install dirmngr -y --install-recommends

# Install R
RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu xenial/" | tee -a /etc/apt/sources.list && \
    echo "deb http://ubuntu.connesi.it/ubuntu/ trusty-backports main restricted universe" | tee -a /etc/apt/sources.list && \
    gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 && \
    gpg -a --export E084DAB9 | apt-key add - && \
    apt-get update && \
    apt-get install -y r-base r-base-dev

# Install system tools
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y build-essential && \
  apt-get install -y software-properties-common && \
  apt-get install -y byobu curl git htop man unzip nano wget && \
  rm -rf /var/lib/apt/lists/*

ARG JAVA_MAJOR_VERSION=8

# Install Java
RUN \
  echo oracle-java${JAVA_MAJOR_VERSION}-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd${JAVA_MAJOR_VERSION}team/java && \
  apt-get update && \
  apt-get install -y oracle-java${JAVA_MAJOR_VERSION}-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk${JAVA_MAJOR_VERSION}-installer

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-${JAVA_MAJOR_VERSION}-oracle

RUN apt-get install git

# Get the modified version of the framework, passing it from the build command to fetch the latest version 
#ARG GIT_REPO=https://github.com/GabrielePrato/SparkUndeployingFrame.git
#RUN git clone ${GIT_REPO}

# Get the modified version of the framework, to be used if running from local FileSystem 
ADD . ./

WORKDIR SparkUndeployingFrame

# Manage execution permission on needed script
RUN chmod 555 R/install-dev.sh &&\
    chmod 555 build/mvn

# Run all the script needed to install of the framework 
ENV R_HOME /usr/lib/R
RUN ./R/install-dev.sh

# Install sbt 
RUN echo "deb http://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list &&\
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 &&\
    apt-get update &&\
    apt-get install sbt

# Compile the framework through Sbt
RUN sbt package 
RUN sbt assembly 

ENV SPARK_HOME /SparkUndeployingFrame

# Expose a port for the container to be visible from outside 
expose 4040

# Manage permission for executing 
RUN chmod -R 555 bin

# Define entrypoint for the command 
CMD ["/SparkUndeployingFrame/bin/spark-submit"]




