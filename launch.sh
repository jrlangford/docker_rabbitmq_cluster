#!/bin/bash
NODE1=j1
NODE2=j2
NODE3=j3

echo "Launching dns resolver"
docker run -d --name dns -v /var/run/docker.sock:/docker.sock phensley/docker-dns --domain rabbit.com

echo "Launching nodes"
function launch_node {
	NODE=$1
	MGMT_PORT=$2
	HOST=${NODE}-host
	docker run -d \
        	--name=$NODE \
        	-p $MGMT_PORT:15672 \
        	-e RABBITMQ_NODENAME=$NODE \
        	-h ${NODE}.rabbit.com \
        	--dns $(docker inspect -f '{{.NetworkSettings.IPAddress}}' dns) \
        	--dns-search rabbit.com \
		jrlangford/rabbitmq:cluster-ready
}

launch_node $NODE1 15672
launch_node $NODE2 15673
launch_node $NODE3 15674

echo "Sleeping to allow time for initialisation"
sleep 3

echo "Clustering containers"
docker exec $NODE2 bash -c \
	"rabbitmqctl stop_app && \
	rabbitmqctl join_cluster $NODE1@$NODE1 && \
	rabbitmqctl start_app" &
docker exec $NODE3 bash -c \
	"rabbitmqctl stop_app && \
	rabbitmqctl join_cluster $NODE1@$NODE1 && \
	rabbitmqctl start_app" &

wait

echo "Setting cluster to High Availability"
docker exec $NODE1 rabbitmqctl set_policy HA '^(?!amq\.).*' '{"ha-mode": "all"}'

echo
echo "Finished, cluster running!!!"
echo
echo "IP:NODE_PORT - $(docker inspect -f '{{.NetworkSettings.IPAddress}}' $NODE1):5672"
echo "RabbitMQ Management Console - localhost:15672"
