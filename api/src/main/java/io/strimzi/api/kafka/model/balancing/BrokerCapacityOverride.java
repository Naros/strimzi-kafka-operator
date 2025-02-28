/*
 * Copyright Strimzi authors.
 * License: Apache License 2.0 (see the file LICENSE or http://apache.org/licenses/LICENSE-2.0.html).
 */
package io.strimzi.api.kafka.model.balancing;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonPropertyOrder;
import io.strimzi.api.kafka.model.Constants;
import io.strimzi.api.kafka.model.UnknownPropertyPreserving;
import io.strimzi.crdgenerator.annotations.Description;
import io.strimzi.crdgenerator.annotations.Pattern;
import io.sundr.builder.annotations.Buildable;
import lombok.EqualsAndHashCode;

import java.io.Serializable;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Representation of the Cruise Control broker capacity settings for specific brokers.
 */
@Buildable(
        editableEnabled = false,
        generateBuilderPackage = false,
        builderPackage = Constants.FABRIC8_KUBERNETES_API
)
@JsonInclude(JsonInclude.Include.NON_NULL)
@JsonPropertyOrder({"brokers", "inboundNetwork", "outboundNetwork"})
@EqualsAndHashCode
public class BrokerCapacityOverride implements UnknownPropertyPreserving, Serializable {
    private static final long serialVersionUID = 1L;

    private List<Integer> brokers;
    private String inboundNetwork;
    private String outboundNetwork;
    private Map<String, Object> additionalProperties = new HashMap<>(0);

    @JsonInclude(content = JsonInclude.Include.NON_NULL, value = JsonInclude.Include.NON_EMPTY)
    @Pattern("^\\[[0-9,]*\\]$")
    @Description("List of Kafka brokers (broker identifiers).")
    @JsonProperty(required = true)
    public List<Integer> getBrokers() {
        return brokers;
    }

    public void setBrokers(List<Integer> brokers) {
        this.brokers = brokers;
    }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    @Pattern("^[0-9]+([KMG]i?)?B/s$")
    @Description("Broker capacity for inbound network throughput in bytes per second. " +
            "Use an integer value with standard Kubernetes byte units (K, M, G) or their bibyte (power of two) equivalents (Ki, Mi, Gi) per second. " +
            "For example, 10000KiB/s.")
    public String getInboundNetwork() {
        return inboundNetwork;
    }

    public void setInboundNetwork(String inboundNetwork) {
        this.inboundNetwork = inboundNetwork;
    }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    @Pattern("^[0-9]+([KMG]i?)?B/s$")
    @Description("Broker capacity for outbound network throughput in bytes per second. " +
            "Use an integer value with standard Kubernetes byte units (K, M, G) or their bibyte (power of two) equivalents (Ki, Mi, Gi) per second. " +
            "For example, 10000KiB/s.")
    public String getOutboundNetwork() {
        return outboundNetwork;
    }

    public void setOutboundNetwork(String outboundNetwork) {
        this.outboundNetwork = outboundNetwork;
    }

    @Override
    public Map<String, Object> getAdditionalProperties() {
        return this.additionalProperties;
    }

    @Override
    public void setAdditionalProperty(String name, Object value) {
        this.additionalProperties.put(name, value);
    }
}
