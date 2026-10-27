# syntax=docker/dockerfile:1
#
# Overlay carrying the code-search skill. The scc and cs binaries are in the shared base image.

FROM scratch
COPY skills/ /usr/share/kit-code-search/skills/
