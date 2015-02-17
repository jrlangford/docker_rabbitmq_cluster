FROM rabbitmq:3-management
MAINTAINER jonathan.langford@schibsted.com.mx

#Set ERLANG cookie so it is common to all containers in cluster
COPY .erlang.cookie /var/lib/rabbitmq/
RUN chmod 400 /var/lib/rabbitmq/.erlang.cookie
CMD ["rabbitmq-server"]
