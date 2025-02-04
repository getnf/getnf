### Build stage
FROM ubuntu:latest AS builder
RUN apt update && apt install -y sudo vim curl fzf fontconfig xz-utils
RUN useradd -m tester && echo "tester:pass" | chpasswd && usermod -aG sudo tester && chown -R tester:tester /home/tester
USER tester
RUN echo 'export PATH=$HOME/.local/bin:$PATH' > /home/tester/.bash_aliases
RUN mkdir -p /home/tester/.local/bin/
COPY --chown=tester:tester ./getnf /home/tester/.local/bin/getnf
### Runtime stage
FROM ubuntu:latest
COPY --from=builder /home/tester/.local/bin/getnf /home/tester/.local/bin/getnf
WORKDIR /home/tester
CMD ["/bin/bash"]
