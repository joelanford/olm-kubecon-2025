FROM scratch

COPY ./catalog /configs

LABEL operators.operatorframework.io.index.configs.v1=/configs
