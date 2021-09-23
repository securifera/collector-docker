# collector-docker
Dockerfile for manual installation of Recon collector tools


### BUILD INSTRUCTIONS & README
 docker build --build-arg sshkey="local public key file" --build-arg gituser="git username" --build-arg gitpwd="git token" -t collector:test1 .
 
 docker run -d collector_test
