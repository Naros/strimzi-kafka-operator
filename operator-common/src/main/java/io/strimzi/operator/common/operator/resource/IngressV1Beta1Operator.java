/*
 * Copyright Strimzi authors.
 * License: Apache License 2.0 (see the file LICENSE or http://apache.org/licenses/LICENSE-2.0.html).
 */
package io.strimzi.operator.common.operator.resource;

import io.fabric8.kubernetes.api.model.networking.v1beta1.Ingress;
import io.fabric8.kubernetes.api.model.networking.v1beta1.IngressList;
import io.fabric8.kubernetes.client.KubernetesClient;
import io.fabric8.kubernetes.client.dsl.MixedOperation;
import io.fabric8.kubernetes.client.dsl.Resource;
import io.vertx.core.Future;
import io.vertx.core.Vertx;

/**
 * Operations for {@code Ingress}es.
 */
public class IngressV1Beta1Operator extends AbstractResourceOperator<KubernetesClient, Ingress, IngressList, Resource<Ingress>> {

    /**
     * Constructor
     * @param vertx The Vertx instance
     * @param client The Kubernetes client
     */
    public IngressV1Beta1Operator(Vertx vertx, KubernetesClient client) {
        super(vertx, client, "v1beta1.Ingress");
    }

    @Override
    protected MixedOperation<Ingress, IngressList, Resource<Ingress>> operation() {
        return client.network().v1beta1().ingresses();
    }

    /**
     * Succeeds when the Service has an assigned address
     *
     * @param namespace     Namespace
     * @param name          Name of the service
     * @param pollIntervalMs    Interval in which we poll
     * @param timeoutMs     Timeout
     * @return A future that succeeds when the Service has an assigned address.
     */
    public Future<Void> hasIngressAddress(String namespace, String name, long pollIntervalMs, long timeoutMs) {
        return waitFor(namespace, name, "addressable", pollIntervalMs, timeoutMs, this::isIngressAddressReady);
    }

    /**
     * Checks if the Ingress already has assigned ingress address.
     *
     * @param namespace The namespace.
     * @param name The route name.
     * @return Whether the Ingress already has assigned ingress address.
     */
    public boolean isIngressAddressReady(String namespace, String name) {
        Resource<Ingress> resourceOp = operation().inNamespace(namespace).withName(name);
        Ingress resource = resourceOp.get();

        if (resource != null && resource.getStatus() != null && resource.getStatus().getLoadBalancer() != null && resource.getStatus().getLoadBalancer().getIngress() != null && resource.getStatus().getLoadBalancer().getIngress().size() > 0) {
            if (resource.getStatus().getLoadBalancer().getIngress().get(0).getHostname() != null || resource.getStatus().getLoadBalancer().getIngress().get(0).getIp() != null) {
                return true;
            }
        }

        return false;
    }
}
