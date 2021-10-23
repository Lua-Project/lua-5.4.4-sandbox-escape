FROM ubuntu:20.04

# Create LUA directory
RUN mkdir -p /LUA

# Set workspace for command of RUN, CMD, etc in docker image
WORKDIR /LUA

# Add files in current directory to /LUA directory in docker image
COPY ./ /LUA

# Install required libraries
RUN apt update
RUN apt install -y build-essential
RUN apt-get -y install libreadline-dev
RUN apt-get -y install manpages-dev
RUN apt-get -y install git 

# Install Lua 5.4.4
RUN git clone https://github.com/lua/lua.git
WORKDIR /LUA/lua
RUN git reset --hard 87a9573b2eb3f1da8e438f92ade994160d930b09
RUN make

# Set execute permission to setup.sh & Run setup.sh
RUN chmod u+x /LUA/setup.sh
RUN /LUA/setup.sh

